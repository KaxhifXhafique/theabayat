/* abayat – shared shop logic. Pages are built by build.pl; this file adds the cart, filters and WhatsApp ordering. */
const BASE = document.documentElement.dataset.base || '';
const SIZES = ['50','52','54','56','58','60'];
const money = v => 'Rs. ' + v.toLocaleString('en-PK');
const $ = id => document.getElementById(id);
const find = id => PRODUCTS.find(p => p.id === id);
const waLink = text => 'https://wa.me/' + WHATSAPP + '?text=' + encodeURIComponent(text);

function toast(msg){ const t=$('toast'); t.textContent=msg; t.classList.add('show'); clearTimeout(toast.t); toast.t=setTimeout(()=>t.classList.remove('show'),2200); }

/* ---------- menu + categories dropdown ---------- */
$('burger').onclick = () => $('nav').classList.toggle('open');
document.querySelectorAll('.dd-btn').forEach(b => b.onclick = e => {
  e.stopPropagation();
  const dd = b.parentElement, open = !dd.classList.contains('open');
  dd.classList.toggle('open', open); b.setAttribute('aria-expanded', open);
});
document.addEventListener('click', () => document.querySelectorAll('.dd.open').forEach(d => { d.classList.remove('open'); d.querySelector('.dd-btn').setAttribute('aria-expanded', false); }));

/* ---------- cart ---------- */
let cart = [];
try { cart = (JSON.parse(localStorage.getItem('abayat_cart2')) || []).filter(i => find(i.id)); } catch(e){ cart = []; }
cart.forEach(i => { const x = find(i.id); i.n = x.n; i.p = x.p; i.img = x.img[0]; });
const save = () => { try { localStorage.setItem('abayat_cart2', JSON.stringify(cart)); } catch(e){} };
const total = () => cart.reduce((s,i)=>s+i.p*i.q,0);
const qtyAll = () => cart.reduce((s,i)=>s+i.q,0);
const keyOf = i => i.id + '|' + i.s;

function renderCart(){
  $('count').textContent = $('dCount').textContent = qtyAll();
  $('subtotal').textContent = money(total());
  $('checkoutBtn').disabled = !cart.length;
  $('cartBody').innerHTML = cart.length ? cart.map(i=>`
    <div class="item"><img src="${BASE + i.img}" alt="">
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

/* ---------- home page: category tabs and filters ---------- */
function filterCards(grid, cat, limit){
  let shown = 0;
  grid.querySelectorAll('.card').forEach(c => {
    const ok = (cat==='all' || c.dataset.cat===cat) && (!limit || shown < limit);
    c.hidden = !ok; if(ok) shown++;
  });
}
if($('tabGrid')){
  filterCards($('tabGrid'), $('tabs').querySelector('.on').dataset.t, 3);
  $('tabs').onclick = e => { const b=e.target.closest('.tab'); if(!b) return;
    $('tabs').querySelectorAll('.tab').forEach(t=>t.classList.toggle('on', t===b)); filterCards($('tabGrid'), b.dataset.t, 3); };
  $('pills').onclick = e => { const b=e.target.closest('.pill'); if(!b) return;
    $('pills').querySelectorAll('.pill').forEach(t=>t.classList.toggle('on', t===b)); filterCards($('trendGrid'), b.dataset.f); };
}

/* ---------- product page ---------- */
if($('pd')){
  const x = find($('pd').dataset.id);
  let size = '54', qty = 1;
  const updWa = () => $('waBuy').href = waLink(`Assalam o Alaikum, I want to order:\n${x.n}\nSize: ${size}\nQuantity: ${qty}\nPrice: ${money(x.p*qty)}\n${location.href}`);
  updWa();
  $('pd').querySelector('.thumbs').onclick = e => { const b=e.target.closest('[data-img]'); if(!b) return;
    $('mainImg').src = b.dataset.img; $('pd').querySelectorAll('.thumbs button').forEach(t=>t.classList.toggle('on', t===b)); };
  $('sizes').onclick = e => { const b=e.target.closest('[data-s]'); if(!b) return;
    size = b.dataset.s; $('sizes').querySelectorAll('button').forEach(t=>t.classList.toggle('on', t===b)); updWa(); };
  $('qm').onclick = () => { qty = Math.max(1, qty-1); $('qv').textContent = qty; updWa(); };
  $('qp').onclick = () => { qty++; $('qv').textContent = qty; updWa(); };
  $('addBtn').onclick = () => addToCart(x.id, size, qty);
}

renderCart();
