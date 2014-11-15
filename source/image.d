import std.stdio;
import std.conv;
import std.string;
import std.container;
import derelict.freeimage.freeimage;

void load_image(string filename)
{
    auto format = FreeImage_GetFileType(filename.toStringz(), 0);
    if (format == FIF_UNKNOWN)
        throw new Exception("Could not determine file type");
    writeln("Format "~to!string(format));
    auto im = FreeImage_Load(format, filename.ptr);
    if (im == null)
        throw new Exception("Could not load image");
    auto imtype = FreeImage_GetImageType(im);
    writeln("Image type ", imtype);
    auto bpp = FreeImage_GetBPP(im);
    writeln("Image bpp ", bpp);
    scope(exit) FreeImage_Unload(im);
    auto a = Array!int([3]);
    auto b = [3];
    auto c = b.ptr;
}
