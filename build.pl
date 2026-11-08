#!/usr/bin/perl
# Abayat site builder.
# Reads data/products.json and writes every page as plain HTML (good for SEO):
#   index.html, party-wear/, formal-wear/, casual-wear/, abayas/<id>/,
#   products.js (for the cart), sitemap.xml, robots.txt
# Run from the site folder:  perl build.pl
use strict;
use warnings;
use JSON::PP;
use File::Path qw(make_path);
use Digest::MD5 qw(md5_hex);

my $json = JSON::PP->new->utf8->canonical;
open my $in, '<:raw', 'data/products.json' or die "data/products.json: $!";
my $data = $json->decode(do { local $/; <$in> });
close $in;

my %site  = %{ $data->{site} };
my @cats  = @{ $data->{categories} };
my @prods = @{ $data->{products} };
my %cat   = map { $_->{id} => $_ } @cats;
my $URL   = $site{url};
my $today = do { my @t = localtime; sprintf '%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3] };

for my $p (@prods) {
  die "Unknown category '$p->{cat}' for $p->{id}\n" unless $cat{ $p->{cat} };
}

# ---------- helpers ----------
sub esc { my $s = shift // ''; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g; $s }
sub money { my $n = reverse shift; $n =~ s/(\d{3})(?=\d)/$1,/g; 'Rs. ' . reverse $n }
# short content hash so browsers and the Hostinger cache load new CSS/JS after every update
my %ver;
sub ver { my $f = shift; $ver{$f} //= do { open my $h, "<:raw", $f or die "$f: $!"; substr md5_hex(do { local $/; <$h> }), 0, 8 } }
sub img { 'images/products/' . shift }
sub plink { "abayas/$_[0]{id}/" }
sub clink { "$_[0]{slug}/" }
sub short {
  my ($s, $max) = @_;
  return $s if length $s <= $max;
  $s = substr $s, 0, $max - 1;
  $s =~ s/\s+\S*$//;
  "$s\x{2026}";
}
sub jsonld { my $j = JSON::PP->new->canonical->ascii->encode(shift); $j =~ s{</}{<\\/}g; qq{<script type="application/ld+json">$j</script>} }

sub write_page {
  my ($path, $html) = @_;
  (my $dir = $path) =~ s{/[^/]*$}{};
  make_path($dir) if $dir ne $path;
  open my $out, '>:encoding(UTF-8)', $path or die "$path: $!";
  print $out $html;
  close $out;
  print "  wrote $path\n";
}

my $SVG_WA   = '<svg viewBox="0 0 24 24"><path d="M4 20l1.3-3.9A8 8 0 1112 20a8 8 0 01-3.9-1L4 20z"/></svg>';
my $SVG_BAG  = '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1 12H6L5 8z"/><path d="M9 8V6a3 3 0 016 0v2"/></svg>';
my $SVG_HEART = '<svg viewBox="0 0 24 24"><path d="M12 21s-8-5-8-11a4.5 4.5 0 018-2.5A4.5 4.5 0 0120 10c0 6-8 11-8 11z"/></svg>';

# ---------- shared blocks ($r = relative path back to the site root) ----------
sub card {
  my ($p, $r) = @_;
  my $c   = $cat{ $p->{cat} };
  my $l   = $r . plink($p);
  my $n   = esc($p->{n});
  my $tag = $p->{tag} ? '<span class="tag">' . esc($p->{tag}) . '</span>' : '';
  my $old = $p->{o} ? '<s>' . money($p->{o}) . '</s>' : '';
  return <<"HTML";
<article class="card" data-cat="$p->{cat}">
  <div class="ph"><a href="$l"><img src="$r@{[ img($p->{img}[0]) ]}" alt="$n - $c->{name}" loading="lazy" width="600" height="800"></a>
    $tag<button class="wish" aria-label="Add to wishlist" data-wish>$SVG_HEART</button>
    <button class="add" aria-label="Add $n to cart" data-add="$p->{id}">$SVG_BAG</button></div>
  <a class="info" href="$l"><div class="cat-l">$c->{name}</div><h3 class="name">$n</h3>
    <div class="price">$old@{[ money($p->{p}) ]}</div></a>
  <a class="buy" href="$l">View details</a>
</article>
HTML
}

sub head {
  my (%o) = @_;
  my $r      = $o{r};
  my $canon  = $URL . ($o{path} // '');
  my $t      = esc($o{title});
  my $d      = esc($o{desc});
  my $ogimg  = $URL . ($o{image} // 'images/brand-tag.jpg');
  my $type   = $o{ogtype} // 'website';
  my $robots = $o{noindex} ? 'noindex, follow' : 'index, follow, max-image-preview:large';
  my $ld     = join "\n", map { jsonld($_) } @{ $o{ld} // [] };
  return <<"HTML";
<!DOCTYPE html>
<html lang="en-PK" data-base="$r">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$t</title>
<meta name="description" content="$d">
<link rel="canonical" href="$canon">
<meta name="robots" content="$robots">
<meta name="theme-color" content="#a8b69b">
<meta property="og:site_name" content="Abayat">
<meta property="og:type" content="$type">
<meta property="og:title" content="$t">
<meta property="og:description" content="$d">
<meta property="og:url" content="$canon">
<meta property="og:image" content="$ogimg">
<meta property="og:locale" content="en_PK">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$t">
<meta name="twitter:description" content="$d">
<meta name="twitter:image" content="$ogimg">
<link rel="icon" type="image/png" href="${r}images/favicon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Allura&family=Dancing+Script:wght\@500&family=Roboto:wght\@400;500;700&display=swap">
<link rel="stylesheet" href="${r}style.css?v=@{[ ver(q(style.css)) ]}">
$ld
</head>
<body>

<div class="topbar">Free delivery on orders above Rs. 15,000 &middot; Cash on delivery all over Pakistan</div>

<header>
  <div class="wrap head">
    <button class="ib burger" aria-label="Menu" aria-controls="nav" id="burger"><svg viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg></button>
    <a class="logo" href="${r}" aria-label="Abayat - The Modest Edit"><span class="l1">Abayat</span><span class="l2">The Modest Edit</span></a>
    <nav class="nav" id="nav" aria-label="Main">
      <a href="${r}">Home</a>
      <div class="dd">
        <button class="dd-btn" aria-haspopup="true" aria-expanded="false">Categories <span aria-hidden="true">&#9662;</span></button>
        <div class="dd-menu">
@{[ join "\n", map { qq{          <a href="$r} . clink($_) . qq{">$_->{name}</a>} } @cats ]}
        </div>
      </div>
      <a href="${r}#all">All abayas</a>
      <a href="#contact">Contact</a>
    </nav>
    <div class="icons">
      <a class="ib" aria-label="WhatsApp us" data-wa target="_blank" rel="noopener">$SVG_WA</a>
      <button class="ib" aria-label="Open cart" id="openCart">$SVG_BAG<span class="badge" id="count">0</span></button>
    </div>
  </div>
</header>
HTML
}

sub foot {
  my ($r) = @_;
  my $catlinks = join '', map { qq{<li><a href="$r} . clink($_) . qq{">$_->{name} abayas</a></li>} } @cats;
  return <<"HTML";
<footer id="contact">
  <div class="wrap">
    <div class="fbrand"><b>Abayat</b><span>The Modest Edit</span></div>
    <div class="fgrid">
      <div><h4>Order with us</h4><ul><li>WhatsApp: <a data-wa target="_blank" rel="noopener">$site{phone}</a></li><li>Cash on delivery</li><li>Delivery all over Pakistan</li></ul></div>
      <div><h4>Shop</h4><ul>$catlinks<li><a href="${r}#all">All abayas</a></li></ul></div>
      <div><h4>Customer care</h4><ul><li><a data-wa target="_blank" rel="noopener">Return &amp; exchange</a></li><li><a data-wa target="_blank" rel="noopener">Size guide</a></li><li><a data-wa target="_blank" rel="noopener">Contact us</a></li></ul></div>
      <div>
        <h4>Sign up for our newsletter</h4>
        <form class="nl" onsubmit="event.preventDefault();toast('Thank you for subscribing');this.reset()">
          <input type="email" required placeholder="Enter your email address" aria-label="Email address"><button>SUBMIT</button>
        </form>
      </div>
    </div>
    <div class="copy"><span>&copy; 2026 Abayat. All rights reserved.</span><span>Premium abayas online in Pakistan</span></div>
  </div>
</footer>

<a class="wa-float" data-wa target="_blank" rel="noopener">$SVG_WA<span>Chat with us</span></a>

<div class="overlay" id="overlay"></div>
<aside class="drawer" id="drawer" aria-label="Shopping cart">
  <div class="d-head"><span>Your cart (<span id="dCount">0</span>)</span><button class="rm" id="closeCart" aria-label="Close cart">&times;</button></div>
  <div class="d-body" id="cartBody"></div>
  <div class="d-foot">
    <div class="sub"><span>Subtotal</span><span id="subtotal">Rs. 0</span></div>
    <div class="note">Shipping is calculated at checkout.</div>
    <button class="btn" id="checkoutBtn">Checkout</button>
  </div>
</aside>

<div class="modal" id="modal" role="dialog" aria-modal="true" aria-label="Checkout">
  <button class="x" id="closeModal" aria-label="Close">&times;</button>
  <div id="checkoutView">
    <h2>Checkout</h2>
    <p class="note">Your order will be sent to us on WhatsApp.</p>
    <form id="form">
      <div class="f">
        <input name="name" required placeholder="Full name" autocomplete="name">
        <input name="phone" required type="tel" pattern="[0-9+\\-\\s]{10,15}" placeholder="Phone number (e.g. 0300 1234567)" autocomplete="tel">
        <input name="email" type="email" placeholder="Email (optional)" autocomplete="email">
        <input name="city" required placeholder="City" autocomplete="address-level2">
        <textarea name="address" required rows="2" placeholder="Complete delivery address" autocomplete="street-address"></textarea>
        <select name="pay" aria-label="Payment method"><option>Cash on delivery</option><option>Bank transfer</option><option>JazzCash / Easypaisa</option></select>
      </div>
      <div class="sum" id="summary"></div>
      <button class="btn wa" style="width:100%;padding:15px">Send order on WhatsApp</button>
    </form>
  </div>
  <div class="ok" id="okView" hidden>
    <div class="tick">&#10003;</div>
    <h2>Order sent</h2>
    <p style="margin:8px 0 18px;font-size:13px;color:var(--muted)">Thank you, <b id="okName"></b>. Please press <b>Send</b> in WhatsApp to confirm your order <b id="okId"></b>. We will call you to confirm delivery.</p>
    <button class="btn" id="okClose">Continue shopping</button>
  </div>
</div>
<div class="toast" id="toast"></div>

<script src="${r}products.js?v=@{[ ver(q(products.js)) ]}"></script>
<script src="${r}app.js?v=@{[ ver(q(app.js)) ]}"></script>
</body>
</html>
HTML
}

sub crumbs_ld {
  my @items = @_;
  my $i = 0;
  return { '@context' => 'https://schema.org', '@type' => 'BreadcrumbList',
    itemListElement => [ map { { '@type' => 'ListItem', position => ++$i, name => $_->[0], item => $URL . $_->[1] } } @items ] };
}

sub cimg { 'images/' . $_[0]{img} }
sub cat_items { my $c = shift; grep { $_->{cat} eq $c->{id} } @prods }

sub cat_tiles {
  my ($r) = @_;
  join '', map {
    my $c = $_;
    my $count = cat_items($c);
    my $pos = $c->{pos} // 'center top';
    qq{<a class="ctile" href="$r} . clink($c) . qq{"><span class="win"><img src="$r} . cimg($c) . qq{" alt="$c->{name}" loading="lazy" width="600" height="750" style="object-position:$pos"></span>}
    . qq{<h3>$c->{name}</h3><span class="cnt">@{[ $count ? "$count styles" : 'Coming soon' ]}</span></a>}
  } @cats;
}

# ---------- products.js (used by the cart and WhatsApp ordering) ----------
{
  my @js = map { { id => $_->{id}, n => $_->{n}, p => $_->{p}, cat => $_->{cat}, img => [ map { img($_) } @{ $_->{img} } ], url => plink($_) } } @prods;
  my $list = JSON::PP->new->canonical->ascii->pretty->encode(\@js);
  write_page('products.js', "/* Generated by build.pl from data/products.json - edit that file, then run: perl build.pl */\n"
    . "const WHATSAPP = '$site{whatsapp}';\nconst PRODUCTS = $list;\n");
}

# ---------- home page ----------
{
  my $r = '';
  # a product section for every category that has products
  my $sections = join '', map {
    my $c = $_;
    my @list = cat_items($c);
    my $cta = @list % 5
      ? qq{<a class="cta-tile" href="} . clink($c) . qq{"><b>$c->{name}</b><span>View all &rarr;</span></a>} : '';
    qq{<section class="sec cat-sec" id="$c->{slug}">
  <div class="wrap">
    <div class="sec-head"><h2 class="title">$c->{name}</h2><a class="more" href="} . clink($c) . qq{">View all @{[ scalar @list ]} styles &rarr;</a></div>
    <div class="grid5">} . join('', map { card($_, $r) } @list) . qq{$cta</div>
  </div>
</section>
}
  } grep { scalar cat_items($_) } @cats;
  my $catlinks = join ', ', map { qq{<a href="} . clink($_) . qq{">} . lc($_->{name}) . '</a>' } @cats;

  my $ld = [
    { '@context' => 'https://schema.org', '@type' => 'ClothingStore', name => 'Abayat', slogan => 'The Modest Edit', url => $URL,
      logo => $URL . 'images/brand-tag.jpg', image => $URL . 'images/categories/simple-plain.jpg', telephone => '+' . $site{whatsapp},
      priceRange => 'Rs. 6,999', areaServed => 'PK', address => { '@type' => 'PostalAddress', addressCountry => 'PK' },
      description => 'Premium abayas online in Pakistan - simple, casual, party wear, embroidered and formal abayas, hijabs, shawls and prayer wear with cash on delivery.' },
    { '@context' => 'https://schema.org', '@type' => 'WebSite', name => 'Abayat', url => $URL },
  ];

  write_page('index.html', head(r => $r, path => '', ld => $ld, image => 'images/categories/simple-plain.jpg',
      title => 'Abayat | The Modest Edit - Premium Abayas Online in Pakistan',
      desc  => 'Shop premium abayas online in Pakistan: simple, casual, party wear, embroidered and formal abayas, plus hijabs, shawls and prayer wear. Cash on delivery nationwide.')
    . <<"HTML" . foot($r));

<main>
<section class="hero" id="top">
  <img class="hero-bg" src="images/categories/simple-plain.jpg" alt="Woman in a plain black abaya and hijab" width="1599" height="1066">
  <div class="wrap hero-in">
    <div class="hero-text">
      <div class="hero-brand">Abayat</div>
      <div class="hero-tag">The Modest Edit</div>
      <h1>Modesty, Beautifully Worn.</h1>
      <p>Discover premium party, formal &amp; everyday abayas in soft, flowy and breathable fabrics - designed to drape gracefully and feel effortlessly elegant.</p>
      <a class="btn" href="#categories">Shop the collection</a>
    </div>
  </div>
</section>

<section class="sec" id="categories">
  <div class="wrap">
    <div class="center-head">
      <h2 class="title">Shop By Category</h2>
    </div>
    <div class="ctiles">@{[ cat_tiles($r) ]}</div>
  </div>
</section>

<div id="all">
$sections</div>

<section class="sec about">
  <div class="wrap about-in">
    <img src="images/brand-tag.jpg" alt="Abayat - The Modest Edit brand tag" loading="lazy" width="1280" height="1280">
    <div>
      <div class="kicker">About Abayat</div>
      <h2 class="title">Buy abayas online in Pakistan</h2>
      <p>Abayat brings you premium modest wear for every part of your day. Our <a href="party-wear/">party wear abayas</a> feature pearl work, beads and lace for weddings and Eid, our <a href="embroidered-abaya/">embroidered abayas</a> add delicate detail, and our <a href="formal-wear/">corporate and formal abayas</a> come in rich colours like navy blue for office and special days. For every day, choose <a href="casual-wear/">daily wear and casual abayas</a> or a clean <a href="simple-abaya/">simple / plain abaya</a>.</p>
      <p>Every abaya is Rs. 6,999, available in sizes 50 to 60, and delivered all over Pakistan with cash on delivery. Shop all categories: $catlinks. Order in a minute on WhatsApp.</p>
    </div>
  </div>
</section>
</main>

HTML
}

# ---------- category pages ----------
for my $c (@cats) {
  my $r = '../';
  my @list  = cat_items($c);
  my $cards = join '', map { card($_, $r) } @list;
  my $other = join '', map { qq{<a class="pill" href="$r} . clink($_) . qq{">$_->{name}</a>} } grep { $_ != $c } @cats;
  my $pos   = $c->{bpos} // $c->{pos} // 'center';
  my $i = 0;
  my $ld = [
    crumbs_ld([ 'Home', '' ], [ $c->{name}, clink($c) ]),
    { '@context' => 'https://schema.org', '@type' => 'CollectionPage', name => $c->{title}, url => $URL . clink($c), description => $c->{intro},
      @list ? (mainEntity => { '@type' => 'ItemList', itemListElement => [ map { { '@type' => 'ListItem', position => ++$i, url => $URL . plink($_), name => $_->{n} } } @list ] }) : () },
  ];
  my $body = @list ? qq{<div class="grid4">$cards</div>}
    : qq{<div class="soon"><h2>New styles coming soon</h2><p>We are adding $c->{name} to the shop. Message us on WhatsApp to ask what is available or to place an order.</p><a class="btn wa" data-wa target="_blank" rel="noopener">Ask on WhatsApp</a></div>};
  write_page(clink($c) . 'index.html', head(r => $r, path => clink($c), ld => $ld, image => cimg($c), noindex => !@list,
      title => "$c->{title} | Abayat",
      desc  => short($c->{intro}, 150))
    . <<"HTML" . foot($r));

<main>
<section class="cat-banner@{[ $c->{tall} ? q( tall) : q() ]}">
  <img src="$r@{[ cimg($c) ]}" alt="$c->{name}" width="1600" height="800" style="object-position:$pos">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><a href="$r">Home</a> / <span>$c->{name}</span></nav>
    <h1>$c->{name}</h1>
    <p>$c->{tagline}</p>
  </div>
</section>
<section class="sec pd-sec">
  <div class="wrap">
    <div class="cat-head">
      <div class="kicker">@{[ @list ? scalar(@list) . ' styles' : 'Coming soon' ]}</div>
      <h2 class="title">$c->{title}</h2>
      <p>$c->{intro}</p>
      <div class="pills">$other</div>
    </div>
    $body
  </div>
</section>
</main>

HTML
}

# ---------- product pages ----------
for my $p (@prods) {
  my $r = '../../';
  my $c = $cat{ $p->{cat} };
  my $n = esc($p->{n});
  my $sizes = join '', map { qq{<button class="@{[ $_ eq '54' ? 'on' : '' ]}" data-s="$_">$_</button>} } qw(50 52 54 56 58 60);
  my $thumbs = join '', map { my $k = $_; qq{<button class="@{[ $k ? '' : 'on' ]}" data-img="$r@{[ img($p->{img}[$k]) ]}" aria-label="Photo @{[ $k + 1 ]}"><img src="$r@{[ img($p->{img}[$k]) ]}" alt="$n photo @{[ $k + 1 ]}" width="76" height="101"></button>} } 0 .. $#{ $p->{img} };
  my $feats = join '', map { '<li>' . esc($_) . '</li>' } @{ $p->{f} };
  my @rel = grep { $_->{cat} eq $p->{cat} && $_ != $p } @prods;
  push @rel, grep { $_->{cat} ne $p->{cat} } @prods;
  my $related = join '', map { card($_, $r) } @rel[0 .. 3];
  my $old = $p->{o} ? '<s>' . money($p->{o}) . '</s>' : '';

  my $ld = [
    crumbs_ld([ 'Home', '' ], [ $c->{name}, clink($c) ], [ $p->{n}, plink($p) ]),
    { '@context' => 'https://schema.org', '@type' => 'Product', name => $p->{n}, sku => $p->{id},
      image => [ map { $URL . img($_) } @{ $p->{img} } ], description => $p->{d}, color => $p->{color},
      category => "Women's Clothing > Abayas > $c->{name}", brand => { '@type' => 'Brand', name => 'Abayat' },
      offers => { '@type' => 'Offer', url => $URL . plink($p), priceCurrency => $site{currency}, price => $p->{p},
        availability => 'https://schema.org/InStock', itemCondition => 'https://schema.org/NewCondition',
        seller => { '@type' => 'Organization', name => 'Abayat' } } },
  ];
  write_page(plink($p) . 'index.html', head(r => $r, path => plink($p), ld => $ld, image => img($p->{img}[0]), ogtype => 'product',
      title => "$p->{n} - $c->{name} | Abayat",
      desc  => short($p->{d}, 110) . ' ' . money($p->{p}) . ', cash on delivery in Pakistan.')
    . <<"HTML" . foot($r));

<main>
<section class="sec pd-sec">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><a href="$r">Home</a> / <a href="$r@{[ clink($c) ]}">$c->{name}</a> / <span>$n</span></nav>
    <div class="pd" id="pd" data-id="$p->{id}">
      <div class="gallery">
        <div class="main"><img id="mainImg" src="$r@{[ img($p->{img}[0]) ]}" alt="$n - $c->{name}" width="600" height="800"></div>
        <div class="thumbs">$thumbs</div>
      </div>
      <div class="pinfo">
        <div class="kicker"><a href="$r@{[ clink($c) ]}">$c->{name}</a></div>
        <h1>$n</h1>
        <div class="price big">$old@{[ money($p->{p}) ]}</div>
        <p class="desc">@{[ esc($p->{d}) ]}</p>
        <div class="meta"><span>Colour: <b>@{[ esc($p->{color}) ]}</b></span><span>Category: <b>$c->{name}</b></span></div>
        <div class="lbl">Size (length in inches)</div>
        <div class="sizes" id="sizes">$sizes</div>
        <div class="lbl">Quantity</div>
        <div class="qty big"><button id="qm" aria-label="Decrease">&minus;</button><span id="qv">1</span><button id="qp" aria-label="Increase">+</button></div>
        <div class="actions">
          <a class="btn wa" id="waBuy" target="_blank" rel="noopener">Order on WhatsApp</a>
          <button class="btn" id="addBtn">Add to cart</button>
        </div>
        <h2 class="lbl" style="margin-top:24px">Details</h2>
        <ul class="feats">$feats</ul>
        <div class="perks"><span>Cash on delivery</span><span>Delivery all over Pakistan</span><span>Easy returns</span></div>
      </div>
    </div>
  </div>
</section>

<section class="sec" style="padding-top:0">
  <div class="wrap">
    <div class="kicker">You may also like</div>
    <h2 class="title" style="margin-bottom:22px">More abayas</h2>
    <div class="grid4">$related</div>
  </div>
</section>
</main>

HTML
}

# ---------- sitemap + robots ----------
{
  my @urls = ([ '', '1.0' ], (map { [ clink($_), '0.8' ] } grep { scalar cat_items($_) } @cats), (map { [ plink($_), '0.7' ] } @prods));
  my $x = join '', map { "  <url><loc>$URL$_->[0]</loc><lastmod>$today</lastmod><priority>$_->[1]</priority></url>\n" } @urls;
  write_page('sitemap.xml', qq{<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n$x</urlset>\n});
  write_page('robots.txt', "User-agent: *\nAllow: /\nDisallow: /data/\n\nSitemap: ${URL}sitemap.xml\n");
}

print "Done: " . scalar(@prods) . " products, " . scalar(@cats) . " categories.\n";
