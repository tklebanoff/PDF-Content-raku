use v6;

class X::PDF::Image::WrongHeader is Exception {
    has Str $.type is required;
    has Str $.header is required;
    has IO::Handle $.fh is required;
    method message {
        "{$!fh.path} image doesn't have a {$!type} header: {$.header.perl}"
    }
}

class X::PDF::Image::UnknownType is Exception {
    has IO::Path $.path;
    method message {
        for $!path.extension {
            $_
                ?? "can't yet handle files of type: $_"
                !! "unable to determine image-type: {$!path.basename}"
        }
    }
}

role PDF::Content::Image {

    use PDF::DAO;
    method network-endian { True }

    #| lightweight replacement for deprecated $buf.unpack
    method unpack(Buf $buf, *@templ ) {
	my @bytes = $buf.list;
        my Bool \nw = $.network-endian;
        my uint $off = 0;

	@templ.map: {
	    my uint $size = .^nativesize div 8;
	    my uint $v = 0;
            my uint $i = nw ?? 0 !! $size;
            for 1 .. $size {
                $v +<= 8;
                $v += @bytes[$off + (nw ?? $i++ !! --$i)];
	    }
            $off += $size;

	    $v;
	}
    }

    method type(IO::Path $path) {
        given $path.extension {
            when m:i/^ jpe?g $/ { 'JPEG' }
            when m:i/^ gif $/   { 'GIF' }
            when m:i/^ png $/   { 'PNG' }
            default {
                die X::PDF::Image::UnknownType.new( :$path );
            }
        }
    }

    multi method open(Str $path! ) {
        self.open( $path.IO );
    }

    multi method open(IO::Path $io-path) {
        self.open( $io-path.open( :r, :enc<latin-1>) );
    }

    multi method open(IO::Handle $fh!) {
        my $path = $fh.path;
        my Str $type = self.type: $path; 

        require ::('PDF::Content::Image')::($type);
        ::('PDF::Content::Image')::($type).read($fh);
    }

    method inline-to-xobject(Hash $inline-dict, Bool :$invert) {

        my constant %Abbreviations = %(
            # [PDF 1.7 TABLE 4.43 Entries in an inline image object]
            :BPC<BitsPerComponent>,
            :CS<ColorSpace>,
            :D<Decode>,
            :DP<DecodeParms>,
            :F<Filter>,
            :H<Height>,
            :IM<ImageMask>,
            :I<Interpolate>,
            :W<Width>,
            # [PDF 1.7 TABLE 4.44 Additional abbreviations in an inline image object]
            :G<DeviceGray>,
            :RGB<DeviceRGB>,
            :CMYK<DeviceCMYK>,
            # Notes:
            # 1. Ambiguous 'Indexed' entry seems to be a typo in the spec
            # 2. filter abbreviations are handled in PDF::Storage::Filter
            );

        my $alias = $invert ?? %Abbreviations.invert.Hash !! %Abbreviations;

        my %xobject-dict = $inline-dict.pairs.map: {
            ($alias{.key} // .key) => .value
        }

        %xobject-dict;
    }

    method inline-content {

        # for serialization to content stream ops: BI dict ID data EI
        use PDF::Content::Ops :OpNames;
        use PDF::DAO::Util :to-ast-native;
        # serialize to content ops
        my %dict = to-ast-native(self).value.list;
        %dict<Type Subtype Length>:delete;
        %dict = self.inline-to-xobject( %dict, :invert );

        [ (BeginImage) => [ :%dict ],
          (ImageData)  => [ :$.encoded ],
          (EndImage)   => [],
        ]
    }

}
