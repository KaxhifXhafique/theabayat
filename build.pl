#!/usr/bin/perl
# abayat site builder.
# Reads data/products.json and writes every page as plain HTML (good for SEO):
#   index.html, party-wear/, formal-wear/, casual-wear/, abayas/<id>/,
#   products.js (for the cart), sitemap.xml, robots.txt
# Run from the site folder:  perl build.pl
use strict;
use warnings;
use JSON::PP;
use File::Path qw(make_path);

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
  <div class="ph"><a href="$l"><img src="$r@{[ img($p->{img}[0]) ]}" alt="$n $c->{name} abaya" loading="lazy" width="600" height="800"></a>
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
  my $ogimg  = $URL . ($o{image} // 'images/cover.jpg');
  my $type   = $o{ogtype} // 'website';
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
<meta name="robots" content="index, follow, max-image-preview:large">
<meta name="theme-color" content="#1c1b1a">
<meta property="og:site_name" content="abayat">
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
<link rel="icon" type="image/png" href="${r}images/logo.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght\@400;500;600&display=swap">
<link rel="stylesheet" href="${r}style.css">
$ld
</head>
<body>

<div class="topbar">Premium abayas up to <b>40% off</b> &middot; Free delivery on orders above Rs. 15,000 &middot; Cash on delivery all over Pakistan</div>

<header>
  <div class="wrap head">
    <button class="ib burger" aria-label="Menu" aria-controls="nav" id="burger"><svg viewBox="0 0 24 24"><path d="M3 6h18M3 12h18M3 18h18"/></svg></button>
    <a class="logo" href="${r}"><img src="${r}images/logo.png" alt="abayat - modest wear, elegant you" width="370" height="170"></a>
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
    <div class="copy"><span>&copy; 2026 abayat. All rights reserved.</span><span>Premium abayas online in Pakistan</span></div>
  </div>
</footer>

<a class="wa-float" data-wa target="_blank" rel="noopener" aria-label="Chat on WhatsApp">$SVG_WA</a>

<div class="overlay" id="overlay"></div>
<aside class="drawer" id="drawer" aria-label="Shopping cart">
  <div class="d-head"><span>Your cart (<span id="dCount">0</span>)</span><button class="rm" id="closeCart" aria-label="Close cart">&times;</button></div>
  <div class="d-body" id="cartBody"></div>
  <div class="d-foot">
    <div class="sub"><span>Subtotal</span><span id="subtotal">Rs. 0</span></div>
    <div class="note">Shipping is calculated at checkout.</div>
    <button class="btn gold" id="checkoutBtn">Checkout</button>
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

<script src="${r}products.js"></script>
<script src="${r}app.js"></script>
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

sub cat_tiles {
  my ($r) = @_;
  join '', map {
    my $c = $_;
    my $count = grep { $_->{cat} eq $c->{id} } @prods;
    qq{<a class="ctile" href="$r} . clink($c) . qq{"><img src="$r} . img($c->{img}) . qq{" alt="$c->{name} abayas" loading="lazy" width="600" height="800">}
    . qq{<div><h3>$c->{name}</h3><span>$count styles &middot; Shop now</span></div></a>}
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
  my $cards = join '', map { card($_, $r) } @prods;
  my $tabs  = join '', map { qq{<button class="tab@{[ $_ == $cats[0] ? ' on' : '' ]}" data-t="$_->{id}">$_->{name}</button>} } @cats;
  my $pills = join '', map { qq{<button class="pill" data-f="$_->{id}">$_->{name}</button>} } @cats;
  my $insta = join '', map { qq{<a href="} . plink($_) . qq{"><img src="} . img($_->{img}[1] // $_->{img}[0]) . qq{" alt="} . esc($_->{n}) . qq{" loading="lazy" width="300" height="300"></a>} } @prods[0 .. 5];
  my $feat  = (grep { $_->{id} eq 'pearl-work-kaftan-abaya' } @prods)[0] // $prods[0];
  (my $featname = $feat->{n}) =~ s{ \(.*}{};

  my $ld = [
    { '@context' => 'https://schema.org', '@type' => 'ClothingStore', name => 'abayat', url => $URL,
      logo => $URL . 'images/logo.png', image => $URL . 'images/cover.jpg', telephone => '+' . $site{whatsapp},
      priceRange => 'Rs. 6,999', areaServed => 'PK', address => { '@type' => 'PostalAddress', addressCountry => 'PK' },
      description => 'Premium abayas online in Pakistan - party wear, formal and casual abayas with cash on delivery.' },
    { '@context' => 'https://schema.org', '@type' => 'WebSite', name => 'abayat', url => $URL },
  ];

  write_page('index.html', head(r => $r, path => '', ld => $ld,
      title => 'abayat | Premium Abayas Online in Pakistan - Party, Formal & Casual',
      desc  => 'Shop premium abayas online in Pakistan. Party wear, formal and casual abayas in Korean nida, georgette and jacquard. Rs. 6,999 with cash on delivery nationwide.')
    . <<"HTML" . foot($r));

<main>
<a class="hero" href="#categories" id="top"><img src="images/cover.jpg" alt="Premium abayas up to 40% off - style, comfort, modesty" width="1983" height="793"></a>

<section class="sec" id="categories">
  <div class="wrap">
    <div class="center-head">
      <div class="kicker">Shop by category</div>
      <h1 class="title">Premium Abayas Online in Pakistan</h1>
      <p>Party wear, formal and casual abayas in soft, flowing fabrics. Order on WhatsApp with cash on delivery.</p>
    </div>
    <div class="ctiles">@{[ cat_tiles($r) ]}</div>
  </div>
</section>

<section class="sec" id="signature" style="padding-top:0">
  <div class="wrap split">
    <a class="split-img" href="@{[ plink($feat) ]}">
      <img src="@{[ img($feat->{img}[0]) ]}" alt="@{[ esc($feat->{n}) ]}" loading="lazy" width="600" height="800">
      <div class="cap"><small>Abaya collection 2026</small><h2>@{[ esc($featname) ]}</h2></div>
    </a>
    <div>
      <div class="tabs" id="tabs">$tabs</div>
      <div class="grid3" id="tabGrid">$cards</div>
    </div>
  </div>
</section>

<section class="sec" id="all" style="padding-top:0">
  <div class="wrap">
    <div class="trend-head">
      <div><div class="kicker">Our collection</div><h2 class="title">All abayas</h2></div>
      <div class="pills" id="pills"><button class="pill on" data-f="all">All abayas</button>$pills</div>
    </div>
    <div class="grid6" id="trendGrid">$cards</div>
  </div>
</section>

<section class="sec" id="edit" style="background:var(--soft)">
  <div class="wrap">
    <div class="edit-head">
      <div class="kicker">abayat edit</div>
      <h2 class="title">The abaya edit</h2>
      <p>Soft fabrics, quiet detail and a fit made for every day, prayer and occasion.</p>
    </div>
    <div class="mosaic">
@{[ join "\n", map { my ($c, $h, $btn) = @$_; qq{      <a class="tile" href="} . clink($c) . qq{"><img src="} . img($c->{img}) . qq{" alt="$c->{name} abayas" loading="lazy"><div><small>$c->{name}</small><h3>$h</h3>$btn</div></a>} }
      ([ $cats[0], 'Beads, pearls and lace for weddings, Eid and parties.', '<span class="btn">Explore</span>' ],
       [ $cats[1], 'Refined abayas for office and special days', '' ],
       [ $cats[2], 'Light and easy for every day', '' ]) ]}
    </div>
  </div>
</section>

<section class="sec seo-text">
  <div class="wrap">
    <h2 class="title">Buy abayas online in Pakistan</h2>
    <p>abayat brings you premium abayas for every part of your day. Our <a href="party-wear/">party wear abayas</a> feature pearl work, beads and lace for weddings and Eid. Our <a href="formal-wear/">formal abayas</a> come in rich colours like navy blue, coffee brown and black, while our <a href="casual-wear/">casual abayas</a> are light, breathable and easy to wear daily. Every abaya is Rs. 6,999, available in sizes 50 to 60, and delivered all over Pakistan with cash on delivery. Order in a minute on WhatsApp.</p>
  </div>
</section>

<section class="sec insta">
  <div class="wrap">
    <h2 class="title" style="text-transform:none;font-size:24px">Follow us on Instagram</h2>
    <p>Join our community for daily inspiration and a closer look at our abayas.</p>
    <div class="insta-row">$insta</div>
    <a class="btn" href="#" onclick="toast('Add your Instagram link here');return false">Visit Instagram</a>
  </div>
</section>
</main>

HTML
}

# ---------- category pages ----------
for my $c (@cats) {
  my $r = '../';
  my @list  = grep { $_->{cat} eq $c->{id} } @prods;
  my $cards = join '', map { card($_, $r) } @list;
  my $other = join '', map { qq{<a class="pill" href="$r} . clink($_) . qq{">$_->{name}</a>} } grep { $_ != $c } @cats;
  my $i = 0;
  my $ld = [
    crumbs_ld([ 'Home', '' ], [ $c->{name}, clink($c) ]),
    { '@context' => 'https://schema.org', '@type' => 'CollectionPage', name => $c->{title}, url => $URL . clink($c), description => $c->{intro},
      mainEntity => { '@type' => 'ItemList', itemListElement => [ map { { '@type' => 'ListItem', position => ++$i, url => $URL . plink($_), name => $_->{n} } } @list ] } },
  ];
  write_page(clink($c) . 'index.html', head(r => $r, path => clink($c), ld => $ld, image => img($c->{img}),
      title => "$c->{title} | abayat",
      desc  => short($c->{intro}, 150))
    . <<"HTML" . foot($r));

<main>
<section class="sec pd-sec">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><a href="$r">Home</a> / <span>$c->{name}</span></nav>
    <div class="cat-head">
      <div class="kicker">@{[ scalar @list ]} styles</div>
      <h1 class="title">$c->{title}</h1>
      <p>$c->{intro}</p>
      <div class="pills"><span class="pill on">$c->{name}</span>$other</div>
    </div>
    <div class="grid4">$cards</div>
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
      category => "Women's Clothing > Abayas > $c->{name}", brand => { '@type' => 'Brand', name => 'abayat' },
      offers => { '@type' => 'Offer', url => $URL . plink($p), priceCurrency => $site{currency}, price => $p->{p},
        availability => 'https://schema.org/InStock', itemCondition => 'https://schema.org/NewCondition',
        seller => { '@type' => 'Organization', name => 'abayat' } } },
  ];
  write_page(plink($p) . 'index.html', head(r => $r, path => plink($p), ld => $ld, image => img($p->{img}[0]), ogtype => 'product',
      title => "$p->{n} - $c->{name} Abaya | abayat",
      desc  => short($p->{d}, 110) . ' ' . money($p->{p}) . ', cash on delivery in Pakistan.')
    . <<"HTML" . foot($r));

<main>
<section class="sec pd-sec">
  <div class="wrap">
    <nav class="crumbs" aria-label="Breadcrumb"><a href="$r">Home</a> / <a href="$r@{[ clink($c) ]}">$c->{name}</a> / <span>$n</span></nav>
    <div class="pd" id="pd" data-id="$p->{id}">
      <div class="gallery">
        <div class="main"><img id="mainImg" src="$r@{[ img($p->{img}[0]) ]}" alt="$n - $c->{name} abaya" width="600" height="800"></div>
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
  my @urls = ([ '', '1.0' ], (map { [ clink($_), '0.8' ] } @cats), (map { [ plink($_), '0.7' ] } @prods));
  my $x = join '', map { "  <url><loc>$URL$_->[0]</loc><lastmod>$today</lastmod><priority>$_->[1]</priority></url>\n" } @urls;
  write_page('sitemap.xml', qq{<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n$x</urlset>\n});
  write_page('robots.txt', "User-agent: *\nAllow: /\nDisallow: /data/\n\nSitemap: ${URL}sitemap.xml\n");
}

print "Done: " . scalar(@prods) . " products, " . scalar(@cats) . " categories.\n";
