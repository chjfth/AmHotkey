How to debug python scripts here?

Two steps:
1. Find a image file in Explorer, Ctrl+C copy it, or copy its path.
2. Run in a CMD window with python.exe, as follows:


[D:\gitw\AmHotkey\Everpic] (2020-03-24 10:58:09.19)
> python everpic_batch.pyw
txtpath= c:\users\chj\appdata\local\temp\Everpic\imagelist-20200324_105816.464.(701x494).txt

imagelist-20200324_105816.464.(701x494).txt
should have content like this:

PNG(32-bit), 473 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105815.753.png
PNG(8-bit), 220 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105815.945.png
JPG(95%), 111 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.245.jpg
JPG(80%), 49 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.279.jpg
JPG(60%), 32 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.315.jpg
JPG(40%), 24 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.345.jpg
JPG(20%), 16 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.376.jpg
JPG(10%), 11 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.405.jpg
JPG(5%), 8 KB|c:\users\chj\appdata\local\temp\Everpic\everpic-20200324_105816.435.jpg

And, those c:\users\chj\appdata\local\temp\...png(s) and jpg(s) show have been created on your disk.

NOTE: This works because everpic_batch.pyw take clipboard content as its input.
