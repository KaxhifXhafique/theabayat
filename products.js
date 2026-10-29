/* ============================================================
   abayat – product list
   To add a product: copy one { ... } block, change the values,
   and put its photos in images/products/.
   id    : short unique name used in the page link (no spaces)
   n     : product name
   p     : price in Rs.          o : old price (0 = no discount)
   t     : style  -> 'Kaftan' | 'Closed' | 'Open'
   g     : sections on the home page -> 'signature' | 'essentials' | 'party'
   tag   : small label on the photo ('' for none)
   img   : photos, first one is the main photo
   ============================================================ */
const WHATSAPP = '923331234567'; // 0333 1234567 in international format

const PRODUCTS = [
 {id:'coffee-brown-straight-lace-abaya', n:'Straight Lace Abaya (Coffee Brown)', p:6999, o:0, t:'Open', g:['signature','essentials'], tag:'New',
  d:'A rich coffee brown abaya in soft jacquard fabric with a subtle tonal pattern. Finished with delicate embroidered lace on the sleeves for a graceful, feminine touch.',
  f:['Soft jacquard fabric with tonal print','Embroidered lace finish on sleeves','Flowy, comfortable fall','Suitable for daily and occasion wear'],
  img:['coffee-brown-1.jpg','coffee-brown-2.jpg','coffee-brown-3.jpg','coffee-brown-4.jpg','coffee-brown-5.jpg']},

 {id:'imported-textured-korean-nida', n:'Imported Textured Korean Nida Navy Blue Abaya (Deep Navy Blue)', p:6999, o:0, t:'Open', g:['signature','essentials'], tag:'New',
  d:'A deep navy blue abaya in imported textured Korean nida. The fabric has a soft sheen and a woven floral texture, with fine cut-work lace on the cuffs.',
  f:['Imported textured Korean nida','Cut-work lace cuffs','Deep navy blue abaya','Soft, breathable and easy to carry'],
  img:['textured-nida-1.jpg','textured-nida-2.jpg','textured-nida-3.jpg']},

 {id:'korean-georgette-abaya', n:'Korean Georgette Abaya (Dusty Rose)', p:6999, o:0, t:'Closed', g:['essentials','party'], tag:'',
  d:'A dusty rose abaya in flowing Korean georgette, decorated with hand-finished black beads, sequins and pearl appliqué on the sleeves and back.',
  f:['Premium Korean georgette','Beaded and sequinned appliqué on sleeves and back','Light, flowy drape','Perfect for parties and events'],
  img:['korean-georgette-1.jpg','korean-georgette-2.jpg','korean-georgette-3.jpg','korean-georgette-4.jpg','korean-georgette-5.jpg','korean-georgette-6.jpg']},

 {id:'party-wear-blood-red-abaya', n:'Party Wear Abaya (Blood Red)', p:6999, o:0, t:'Kaftan', g:['signature','party'], tag:'Party wear',
  d:'A bold blood red kaftan abaya in jacquard satin with a gathered waist and pearl-flower embellishment. Wide batwing sleeves finished with pearl leaf detail.',
  f:['Jacquard satin fabric','Pearl-flower waist detail','Wide batwing sleeves with pearl motifs','Made for weddings, Eid and parties'],
  img:['blood-red-1.jpg','blood-red-2.jpg']},

 {id:'pearl-work-kaftan-abaya', n:'Pearl Work Kaftan Abaya (Champagne)', p:6999, o:0, t:'Kaftan', g:['signature','party'], tag:'New',
  d:'An elegant champagne kaftan abaya in soft satin jacquard with a leaf pattern. A pleated waist with pearl flowers and pearl work on the sleeves gives it a luxurious finish.',
  f:['Satin jacquard with leaf pattern','Pearl-flower pleated waist','Pearl work on sleeves','Relaxed kaftan fit'],
  img:['pearl-kaftan-1.jpg','pearl-kaftan-2.jpg','pearl-kaftan-3.jpg']},

 {id:'plain-korean-nida-dusty-blue', n:'Plain Korean Nida Abaya (Dusty Blue)', p:6999, o:0, t:'Open', g:['essentials','party'], tag:'',
  d:'A flowy, soft and lightweight abaya in plain Korean nida, in a calm dusty blue shade. Black beaded appliqué on the sleeves makes it party-ready.',
  f:['Plain Korean nida','Flowy, soft and lightweight','Black beaded sleeve appliqué','Party wear'],
  img:['dusty-blue-1.jpg','dusty-blue-2.jpg','dusty-blue-3.jpg']}
];

PRODUCTS.forEach(x => x.img = x.img.map(f => 'images/products/' + f));
