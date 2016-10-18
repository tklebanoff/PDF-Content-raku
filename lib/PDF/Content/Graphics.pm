use v6;

use PDF::Content;

#| this role is applied to PDF::Content::Type::Page, PDF::Content::Type::Pattern and PDF::Content::Type::XObject::Form
role PDF::Content::Graphics {

    use PDF::Content;
    use PDF::Content::Ops :OpNames;

    has PDF::Content $!pre-gfx; #| prepended graphics
    method pre-gfx { $!pre-gfx //= PDF::Content.new( :parent(self) ) }
    method pre-graphics(&code) { self.pre-gfx.graphics( &code ) }

    has PDF::Content $!gfx;     #| appended graphics
    method gfx(|c) {
	$!gfx //= do {
	    my Pair @ops = self.contents-parse;
	    my PDF::Content $gfx .= new( :parent(self), |c );
	    if @ops && ! (@ops[0].key eq OpNames::Save && @ops[*-1].key eq OpNames::Restore) {
		@ops.unshift: OpNames::Save => [];
		@ops.push: OpNames::Restore => [];
	    }
	    $gfx.ops: @ops;
	    $gfx;
	}
    }
    method graphics(&code) { self.gfx.graphics( &code ) }
    method text(&code) { self.gfx.text( &code ) }
    method canvas(&code) { self.gfx.canvas( &code ) }

    method contents-parse(Str $contents = $.contents ) {
        PDF::Content.parse($contents);
    }

    method contents returns Str {
	$.decoded // '';
    }

    method render(&callback) {
	die "too late to install render callback"
	    if $!gfx;
	self.gfx(:&callback);
    }

    method cb-finish {

        my $prepend = $!pre-gfx && $!pre-gfx.ops
            ?? $!pre-gfx.content ~ "\n"
            !! '';

        my $append = $!gfx && $!gfx.ops
            ?? $!gfx.content
            !! '';

        self.decoded = $prepend ~ $append;
    }

}
