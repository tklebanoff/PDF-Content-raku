use v6;

role PDF::Content::Resourced {

    method !resource-dict { self.Resources //= {} }

    method core-font(|c) {
	self!resource-dict.core-font(|c);
    }
    method use-font($obj, |c) {
	self!resource-dict.use-font($obj, |c);
    }
    method use-resource($obj, |c) {
	self!resource-dict.resource($obj, |c);
    }
    method resource-key($obj, |c) {
	self!resource-dict.resource-key($obj, |c);
    }

    #| my %fonts = $pdf.page(1).resources('Font');
    multi method resources('ProcSet') {
	my @entries;
	my $resource-entries = .ProcSet with self.Resources;
	@entries = .keys.map( { $resource-entries[$_] } )
	    with $resource-entries;
	@entries;
    }
    multi method resources(Str $type) is default {
        my Hash $resource-entries;
	with self.Resources -> $resources {
            $resource-entries = $resources{$type}
              if $resources{$type}:exists;
        }
	my %entries = .keys.map( { $_ => $resource-entries{$_} } )
	    with $resource-entries;
	%entries;
    }

    method resource-entry(|c) {
        .resource-entry(|c) with self.Resources;
    }

    method find-resource(|c ) {
        .find-resource(|c)
            with self.Resources;
    }

    method images(Bool :$inline = True) {
	my %forms = self.resources: 'XObject';
	my @images = %forms.values.grep( *.<Subtype> eq 'Image');
	@images.append: self.gfx.inline-images
	    if $inline;
        @images;
    }

}
