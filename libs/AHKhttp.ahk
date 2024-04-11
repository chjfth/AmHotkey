; [2024-04-10] Original: https://github.com/jleb/AHKsock

#Include %A_LineFile%\..\AHKsock.ahk
#Include %A_LineFile%\..\debugwin.ahk

class Uri
{
	Decode(str) {
		Loop
			If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
				StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
			Else Break
		Return, str
	}

	Encode(str) {
		f = %A_FormatInteger%
		SetFormat, Integer, Hex
		If RegExMatch(str, "^\w+:/{0,2}", pr)
			StringTrimLeft, str, str, StrLen(pr)
		StringReplace, str, str, `%, `%25, All
		Loop
			If RegExMatch(str, "i)[^\w\.~%]", char)
				StringReplace, str, str, %char%, % "%" . Asc(char), All
			Else Break
		SetFormat, Integer, %f%
		Return, pr . str
	}
}

class HttpServer
{
	static servers := {}

	static _FeatureId := "AHKhttp"
	;
	dbg(newmsg, msglv){
		static s_prepared := false
		if(!s_prepared) {
			AmDbg_SetDesc(HttpServer._FeatureId, "Debug messages from AHKhttp.ahk, the simple HTTP server .")
			s_prepared := true
		}
		Amdbg_output(HttpServer._FeatureId
				, Format("[{}] {}", HttpServer._FeatureId, newmsg)
			, msglv)
	}
	dbg0(msg){
		this.dbg(msg, 0)
	}
	dbg1(msg){
		this.dbg(msg, 1)
	}
	dbg2(msg){
		this.dbg(msg, 2)
	}

	LoadMimes(file) {
		
		this.dbg2(Format("LoadMimes(""{}"")", file))
		
		if (!FileExist(file)) {
			this.dbg1(Format("LoadMimes(""{}"") error. File not exist.", file))
			return false
		}

		FileRead, data, % file
		types := StrSplit(data, "`n")
		this.mimes := {}
		for i, data in types {
			info := StrSplit(data, " ")
			type := info.Remove(1)
			; Seperates type of content and file types
			info := StrSplit(LTrim(SubStr(data, StrLen(type) + 1)), " ")

			for i, ext in info {
				ext := Trim(ext, " `t`r`n")
				; AmDbg0(Format("Mimetype: {} -> {}", ext, type))
				this.mimes[ext] := type
			}
		}
		return true
	}

	GetMimeType(file) {
		default := "text/plain"
		if (!this.mimes) {
			return default
		}

		SplitPath, file,,, ext
		type := this.mimes[ext]
		; AmDbg0("GetMimeType(): " ext " -> " type)
		if (!type)
			return default
		return type
	}

	ServeFile(ByRef response, file) {
		f := FileOpen(file, "r")
		length := f.RawRead(data, f.Length)
		f.Close()

		if(length<=0) {
			this.dbg1("Read-file error: " file)
			response.status := 400
			return 0
		}

		this.dbg2("Serving file: " file)

		response.SetBody(data, length)
		response.headers["Content-Type"] := this.GetMimeType(file)
		return length
	}

	SetPaths(paths_prefix) {
		
		this.paths := paths_prefix
		
		dbgpaths := ""
		for key, val in paths_prefix
		{
			dbgpaths .= Format("  {} → {}()`n", key, val.name)
		}
		this.dbg2("SetPaths():`n" dbgpaths)
	}

	Handle(ByRef request) 
	{
		response := new HttpResponse()

		; [2024-04-10] Chj: Do string prefix-match for `request.path`
		; So a "/abc/" routine will process "/abc/some.file" request.
		
		keylist := dev_objkeys(this.paths)
		paths_ordered := ahk_SortArrayReturnNew(keylist, "R") ; R: Reverse sort, so "/" goes last.
			; Will get path from longest to shorted, like: /abcd/ , /abc/ , then /
		for index, path_prefix in paths_ordered
		{
			; AmDbg0("chking path_prefix: " path_prefix)
			if(StrIsStartsWith(request.path, path_prefix))
			{
				this.paths[path_prefix].(request, response, this)
			
				this.dbg2(Format("{} - {}", response.status, request.path))
				
				return response
			}
		}

		this.dbg1(Format("404 - {}", request.path))

		func := this.paths["404"]
		response.status := 404
		if (func)
			func.(request, response, this)
		
		return response
	}

	Serve(port, is_listen_all:=false) {

		this.port := port
		HttpServer.servers[port] := this

		err := AHKsock_Listen(port, "HttpHandler", is_listen_all)
		
		if(err) {
			this.dbg1(Format("Error starting HTTP server on port {}, WinError={}", port, ErrorLevel))
		}
		else {
			this.dbg1(Format("Success starting HTTP server on port {}", port))
		}
		return err
	}
}

HttpHandler(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
	static sockets := {}

	if (!sockets[iSocket]) {
		sockets[iSocket] := new Socket(iSocket)
		AHKsock_SockOpt(iSocket, "SO_KEEPALIVE", true)
	}
	socket := sockets[iSocket]

	if (sEvent == "DISCONNECTED") {
		socket.request := false
		sockets[iSocket] := false
	} else if (sEvent == "SEND") {
		if (socket.TrySend()) {
			socket.Close()
		}

	} else if (sEvent == "RECEIVED") {
		server := HttpServer.servers[sPort]

		text := StrGet(&bData, "UTF-8")

		; New request or old?
		if (socket.request) {
			; Get data and append it to the existing request body
			socket.request.bytesLeft -= StrLen(text)
			socket.request.body := socket.request.body . text
			request := socket.request
		} else {
			; Parse new request
			request := new HttpRequest(text)

			length := request.headers["Content-Length"]
			request.bytesLeft := length + 0

			if (request.body) {
				request.bytesLeft -= StrLen(request.body)
			}
		}

		if (request.bytesLeft <= 0) {
			request.done := true
		} else {
			socket.request := request
		}

		if (request.done || request.IsMultipart()) {
			response := server.Handle(request)
			if (response.status) {
				socket.SetData(response.Generate())
			}
		}
		if (socket.TrySend()) {
			if (!request.IsMultipart() || request.done) {
				socket.Close()
			}
		}    

	}
}

class HttpRequest
{
	__New(data = "") {
		if (data)
			this.Parse(data)
	}

	GetPathInfo(top) {
		results := []
		while (pos := InStr(top, " ")) {
			results.Insert(SubStr(top, 1, pos - 1))
			top := SubStr(top, pos + 1)
		}
		this.method := results[1]
		this.path := Uri.Decode(results[2])
		this.protocol := top
	}

	GetQuery() {
		pos := InStr(this.path, "?")
		query := StrSplit(SubStr(this.path, pos + 1), "&")
		if (pos)
			this.path := SubStr(this.path, 1, pos - 1)

		this.queries := {}
		for i, value in query {
			pos := InStr(value, "=")
			key := SubStr(value, 1, pos - 1)
			val := SubStr(value, pos + 1)
			this.queries[key] := val
		}
	}

	Parse(data) {
		this.raw := data
		data := StrSplit(data, "`n`r")
		headers := StrSplit(data[1], "`n")
		this.body := LTrim(data[2], "`n")

		this.GetPathInfo(headers.Remove(1))
		this.GetQuery()
		this.headers := {}

		for i, line in headers {
			pos := InStr(line, ":")
			key := SubStr(line, 1, pos - 1)
			val := Trim(SubStr(line, pos + 1), "`n`r ")

			this.headers[key] := val
		}
	}

	IsMultipart() {
		length := this.headers["Content-Length"]
		expect := this.headers["Expect"]

		if (expect = "100-continue" && length > 0)
			return true
		return false
	}
}

class HttpResponse
{
	__New() {
		this.headers := {}
		this.status := 0
		this.protocol := "HTTP/1.1"

		this.SetBodyText("")
	}

	Generate() {
		FormatTime, date,, ddd, d MMM yyyy HH:mm:ss
		this.headers["Date"] := date

		headers := this.protocol . " " . this.status . "`r`n"
		for key, value in this.headers {
			headers := headers . key . ": " . value . "`r`n"
		}
		headers := headers . "`r`n"
		length := this.headers["Content-Length"]

		buffer := new Buffer((StrLen(headers) * 2) + length)
		buffer.WriteStr(headers)

		buffer.Append(this.body)
		buffer.Done()

		return buffer
	}

	SetBody(ByRef body, length) {
		this.body := new Buffer(length)
		this.body.Write(&body, length)
		this.headers["Content-Length"] := length
	}

	SetBodyText(text) {
		this.body := Buffer.FromString(text)
		this.headers["Content-Length"] := this.body.length
	}


}

class Socket
{
	__New(socket) {
		this.socket := socket
	}

	Close(timeout = 5000) {
		AHKsock_Close(this.socket, timeout)
	}

	SetData(data) {
		this.data := data
	}

	TrySend() {
		if (!this.data || this.data == "")
			return false

		p := this.data.GetPointer()
		length := this.data.length

		this.dataSent := 0
		loop {
			if ((i := AHKsock_Send(this.socket, p, length - this.dataSent)) < 0) {
				if (i == -2) {
					return
				} else {
					; Failed to send
					return
				}
			}

			if (i < length - this.dataSent) {
				this.dataSent += i
			} else {
				break
			}
		}
		this.dataSent := 0
		this.data := ""

		return true
	}
}

class Buffer
{
	__New(len) {
		this.SetCapacity("buffer", len)
		this.length := 0
	}

	FromString(str, encoding = "UTF-8") {
		length := Buffer.GetStrSize(str, encoding)
		buffer := new Buffer(length)
		buffer.WriteStr(str)
		return buffer
	}

	GetStrSize(str, encoding = "UTF-8") {
		encodingSize := ((encoding="utf-16" || encoding="cp1200") ? 2 : 1)
		; length of string, minus null char
		return StrPut(str, encoding) * encodingSize - encodingSize
	}

	WriteStr(str, encoding = "UTF-8") {
		length := this.GetStrSize(str, encoding)
		VarSetCapacity(text, length)
		StrPut(str, &text, encoding)

		this.Write(&text, length)
		return length
	}

	; data is a pointer to the data
	Write(data, length) {
		p := this.GetPointer()
		DllCall("RtlMoveMemory", "uint", p + this.length, "uint", data, "uint", length)
		this.length += length
	}

	Append(ByRef buffer) {
		destP := this.GetPointer()
		sourceP := buffer.GetPointer()

		DllCall("RtlMoveMemory", "uint", destP + this.length, "uint", sourceP, "uint", buffer.length)
		this.length += buffer.length
	}

	GetPointer() {
		return this.GetAddress("buffer")
	}

	Done() {
		this.SetCapacity("buffer", this.length)
	}
}
