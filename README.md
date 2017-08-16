# PDF::Content

This Perl 6 module is a library of roles and classes for basic PDF content creation and rendering, including text, images, fonts and general graphics.

It is centered around implementing a graphics state machine and provding support for the operators and graphics variables
as listed in the [PDF::API6 Graphics Documentation](https://github.com/p6-pdf/PDF-API6#appendix-i-graphics).

## Key roles and classes:

### `PDF::Content`
implements a PDF graphics state machine for composition, or rendering:
```
use PDF::Content;
my PDF::Content $gfx .= new;
$gfx.BeginText;
$gfx.Font = 'F1', 16;
$gfx.TextMove(10, 20);
$gfx.ShowText('Hello World');
$gfx.EndText;
say $gfx.Str;
# BT
#  /F1 16 Tf
#  10 20 Td
#  (Hello World) Tj
# ET
```

### `PDF::Content::Image`
supports the loading of some common image formats

It currently supports: PNG, GIF and JPEG.

```
use PDF::Content::Image;
use PDF::Content::XObject;
my PDF::Content::XObject $image = PDF::Content::Image.open: "t/images/lightbulb.gif";
say "image has size {$image.width} X {$image.height}";
say $image.data-uri;
# data:image/gif;base64,R0lGODlhEwATAMQA...
```

### `PDF::Content::Util::Font`
provides simple support for core fonts

```
use PDF::Content::Util::Font;
my $font = PDF::Content::Util::Font::core-font( :family<Times-Roman>, :weight<bold> );
say $font.encode("¶Hi");
say $font.stringwidth("RVX"); # 2166
say $font.stringwidth("RVX", :kern); # 2111
```

### `PDF::Content::Text::Block`
a utility class for creating and outputting simple text lines and paragraphs:

```
use PDF::Content;
use PDF::Content::Util::Font;
use PDF::Content::Text::Block;
my $font = PDF::Content::Util::Font::core-font( :family<helvetica>, :weight<bold> );
my $font-size = 16;
my $text = "Hello.  Ting, ting-ting. Attention! … ATTENTION! ";
my $text-block = PDF::Content::Text::Block.new( :$text, :$font, :$font-size );
my PDF::Content $gfx .= new;
$gfx.BeginText;
$text-block.render($gfx);
$gfx.EndText;
say $gfx.Str;
```

## See Also

- [PDF::Lite](https://github.com/p6-pdf/PDF-Lite-p6) put these classes to work for the creation and manipulation of PDF documents.

- [PDF::API6](https://github.com/p6-pdf/PDF-API6) middle-weight PDF manipulation library.

- [PDF::Render::Cairo](https://github.com/p6-pdf/PDF-Render-Cairo-p6)  experimental lightweight PDF renderer to Cairo supported formats including PNG and SVG.



