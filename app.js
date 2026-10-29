/* abayat – shared shop logic (home page + product page) */
const SIZES = ['50','52','54','56','58','60'];
const money = v => 'Rs. ' + v.toLocaleString('en-PK');
const $ = id => document.getElementById(id);
const find = id => PRODUCTS.find(p => p.id === id);
const link = x => 'product.html?id=' + x.id;
const waLink = text => 'https://wa.me/' + WHATSAPP + '?text=' + encodeURIComponent(text);
const heart = '<svg viewBox="0 0 24 24"><path d="M12 21s-8-5-8-11a4.5 4.5 0 018-2.5A4.5 4.5 0 0120 10c0 6-8 11-8 11z"/></svg>';
const bag = '<svg viewBox="0 0 24 24"><path d="M5 8h14l-1 12H6L5 8z"/><path d="M9 8V6a3 3 0 016 0v2"/></svg>';

function card(x){
  return `<article class="card">
    <div class="ph"><a href="${link(x)}"><img src="${x.img[0]}" alt="${x.n}" loading="lazy"></a>
      ${x.tag?`<span class="tag">${x.tag}</span>`:''}
      <button class="wish" aria-label="Add to wishlist" data-wish>${heart}</button>
      <button class="add" aria-label="Add ${x.n} to cart" data-add="${x.id}">${bag}</button></div>
    <a class="info" href="${link(x)}"><div class="cat-l">${x.t==='Open'?'Open front':x.t} abaya</div><div class="name">${x.n}</div>
      <div class="price">${x.o?`<s>${money(x.o)}</s>`:''}${money(x.p)}</div></a>
    <a class="buy" href="${link(x)}">View details</a>
  </article>`;
}

function toast(msg){ const t=$('toast'); t.textContent=msg; t.classList.add('show'); clearTimeout(toast.t); toast.t=setTimeout(()=>t.classList.remove('show'),2200); }

$('burger').onclick = () => $('nav').classList.toggle('open');

/* ---------- cart ---------- */
let cart = [];
try { cart = (JSON.parse(localStorage.getItem('abayat_cart2')) || []).filter(i => find(i.id)); } catch(e){ cart = []; }
const save = () => { try { localStorage.setItem('abayat_cart2', JSON.stringify(cart)); } catch(e){} };
const total = () => cart.reduce((s,i)=>s+i.p*i.q,0);
const qtyAll = () => cart.reduce((s,i)=>s+i.q,0);
const keyOf = i => i.id + '|' + i.s;

function renderCart(){
  $('count').textContent = $('dCount').textContent = qtyAll();
  $('subtotal').textContent = money(total());
  $('checkoutBtn').disabled = !cart.length;
  $('cartBody').innerHTML = cart.length ? cart.map(i=>`
    <div class="item"><img src="${i.img}" alt="">
      <div><div class="n">${i.n}</div><div class="sz">Size ${i.s}</div><div class="p">${money(i.p)}</div>
        <div class="qty"><button data-dec="${keyOf(i)}" aria-label="Decrease">−</button><span>${i.q}</span><button data-inc="${keyOf(i)}" aria-label="Increase">+</button></div></div>
      <button class="rm" data-del="${keyOf(i)}" aria-label="Remove">×</button></div>`).join('')
    : '<p class="empty">Your cart is empty.<br>Add an abaya to get started.</p>';
  save();
}
function addToCart(id, size, qty){
  const x = find(id); size = size || SIZES[2]; qty = qty || 1;
  const f = cart.find(i => i.id===id && i.s===size);
  f ? f.q += qty : cart.push({id:x.id, n:x.n, p:x.p, img:x.img[0], s:size, q:qty});
  renderCart(); toast('Added to cart'); openDrawer();
}
function openDrawer(){ $('drawer').classList.add('open'); $('overlay').classList.add('open'); }
function closeAll(){ $('drawer').classList.remove('open'); $('modal').classList.remove('open'); $('overlay').classList.remove('open'); }

document.addEventListener('click', e => {
  const a = e.target.closest('[data-add]'); if(a) return addToCart(a.dataset.add);
  const w = e.target.closest('[data-wish]'); if(w) return w.classList.toggle('on');
  const inc = e.target.closest('[data-inc]'), dec = e.target.closest('[data-dec]'), del = e.target.closest('[data-del]');
  const by = k => cart.find(i => keyOf(i)===k);
  if(inc) by(inc.dataset.inc).q++;
  else if(dec){ const i=by(dec.dataset.dec); if(--i.q<1) cart=cart.filter(c=>c!==i); }
  else if(del) cart = cart.filter(i=>keyOf(i)!==del.dataset.del);
  else return;
  renderCart();
});
$('openCart').onclick = openDrawer;
$('closeCart').onclick = $('overlay').onclick = $('closeModal').onclick = closeAll;
document.addEventListener('keydown', e => e.key==='Escape' && closeAll());

/* ---------- checkout: order is sent to our WhatsApp ---------- */
const shipping = () => total() >= 15000 ? 0 : 250;
$('checkoutBtn').onclick = () => {
  if(!cart.length) return;
  $('summary').innerHTML = cart.map(i=>`<div><span>${i.n} (size ${i.s}) × ${i.q}</span><span>${money(i.p*i.q)}</span></div>`).join('') +
    `<div><span>Shipping</span><span>${shipping()?money(shipping()):'Free'}</span></div>
     <div class="tot"><span>Total</span><span>${money(total()+shipping())}</span></div>`;
  $('checkoutView').hidden = false; $('okView').hidden = true;
  $('drawer').classList.remove('open'); $('overlay').classList.add('open'); $('modal').classList.add('open');
};
$('form').onsubmit = e => {
  e.preventDefault();
  const d = Object.fromEntries(new FormData(e.target));
  const id = '#AB' + Math.floor(100000 + Math.random()*900000);
  const msg = [`New order ${id} – abayat`, '',
    ...cart.map(i=>`• ${i.n} – size ${i.s} × ${i.q} = ${money(i.p*i.q)}`),
    `Shipping: ${shipping()?money(shipping()):'Free'}`,
    `Total: ${money(total()+shipping())}`, '',
    `Name: ${d.name}`, `Phone: ${d.phone}`, d.email?`Email: ${d.email}`:null, `City: ${d.city}`, `Address: ${d.address}`, `Payment: ${d.pay}`
  ].filter(l => l !== null).join('\n');
  window.open(waLink(msg), '_blank');
  $('okName').textContent = d.name; $('okId').textContent = id;
  cart = []; renderCart(); e.target.reset();
  $('checkoutView').hidden = true; $('okView').hidden = false;
};
$('okClose').onclick = closeAll;

/* WhatsApp links in the page */
document.querySelectorAll('[data-wa]').forEach(a => a.href = waLink('Assalam o Alaikum, I want to ask about your abayas.'));

/* ---------- home page ---------- */
if($('trendGrid')){
  const renderTabs = g => $('tabGrid').innerHTML = PRODUCTS.filter(x=>x.g.includes(g)).slice(0,3).map(card).join('');
  const renderTrend = f => $('trendGrid').innerHTML = PRODUCTS.filter(x=>f==='all'||x.t===f).map(card).join('') || '<p class="empty">No abayas in this style yet.</p>';
  renderTabs('signature'); renderTrend('all');

  $('catRow').innerHTML = PRODUCTS.slice(0,5)
    .map(x=>`<a class="cat" href="${link(x)}"><img src="${x.img[0]}" alt="${x.n}"><span>${x.n.replace(/ Abaya.*$/,'')}</span></a>`).join('');
  $('instaRow').innerHTML = PRODUCTS.map(x=>`<a href="${link(x)}"><img src="${x.img[1]||x.img[0]}" alt="${x.n}" loading="lazy"></a>`).join('');

  $('tabs').onclick = e => { const b=e.target.closest('.tab'); if(!b) return;
    document.querySelectorAll('.tab').forEach(t=>t.classList.remove('on')); b.classList.add('on'); renderTabs(b.dataset.t); };
  $('pills').onclick = e => { const b=e.target.closest('.pill'); if(!b) return;
    document.querySelectorAll('.pill').forEach(t=>t.classList.remove('on')); b.classList.add('on'); renderTrend(b.dataset.f); };
}

/* ---------- product page ---------- */
if($('pd')){
  const x = find(new URLSearchParams(location.search).get('id'));
  if(!x){
    $('pd').innerHTML = '<p class="empty">This abaya could not be found. <a href="index.html#trending" style="text-decoration:underline">See all abayas</a></p>';
  } else {
    document.title = x.n + ' | abayat';
    $('crumb').textContent = x.n;
    $('pd').innerHTML = `
      <div class="gallery">
        <div class="main"><img id="mainImg" src="${x.img[0]}" alt="${x.n}"></div>
        <div class="thumbs">${x.img.map((s,i)=>`<button class="${i?'':'on'}" data-img="${s}" aria-label="Photo ${i+1}"><img src="${s}" alt=""></button>`).join('')}</div>
      </div>
      <div class="pinfo">
        <div class="kicker">${x.t==='Open'?'Open front':x.t} abaya</div>
        <h1>${x.n}</h1>
        <div class="price big">${x.o?`<s>${money(x.o)}</s>`:''}${money(x.p)}</div>
        <p class="desc">${x.d}</p>
        <div class="lbl">Size (length in inches)</div>
        <div class="sizes" id="sizes">${SIZES.map((s,i)=>`<button class="${i===2?'on':''}" data-s="${s}">${s}</button>`).join('')}</div>
        <div class="lbl">Quantity</div>
        <div class="qty big"><button id="qm" aria-label="Decrease">−</button><span id="qv">1</span><button id="qp" aria-label="Increase">+</button></div>
        <div class="actions">
          <a class="btn wa" id="waBuy" target="_blank" rel="noopener">Order on WhatsApp</a>
          <button class="btn" id="addBtn">Add to cart</button>
        </div>
        <ul class="feats">${x.f.map(l=>`<li>${l}</li>`).join('')}</ul>
        <div class="perks"><span>Cash on delivery</span><span>Delivery all over Pakistan</span><span>Easy returns</span></div>
      </div>`;
    let size = SIZES[2], qty = 1;
    const updWa = () => $('waBuy').href = waLink(`Assalam o Alaikum, I want to order:\n${x.n}\nSize: ${size}\nQuantity: ${qty}\nPrice: ${money(x.p*qty)}\n${location.href}`);
    updWa();
    $('pd').querySelector('.thumbs').onclick = e => { const b=e.target.closest('[data-img]'); if(!b) return;
      $('mainImg').src = b.dataset.img; $('pd').querySelectorAll('.thumbs button').forEach(t=>t.classList.toggle('on', t===b)); };
    $('sizes').onclick = e => { const b=e.target.closest('[data-s]'); if(!b) return;
      size = b.dataset.s; $('sizes').querySelectorAll('button').forEach(t=>t.classList.toggle('on', t===b)); updWa(); };
    $('qm').onclick = () => { qty = Math.max(1, qty-1); $('qv').textContent = qty; updWa(); };
    $('qp').onclick = () => { qty++; $('qv').textContent = qty; updWa(); };
    $('addBtn').onclick = () => addToCart(x.id, size, qty);
    $('related').innerHTML = PRODUCTS.filter(p=>p.id!==x.id).slice(0,4).map(card).join('');
  }
}

renderCart();
