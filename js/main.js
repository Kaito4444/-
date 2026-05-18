'use strict';

// ===== HEADER SCROLL =====
const header = document.getElementById('header');
window.addEventListener('scroll', () => {
  header.classList.toggle('scrolled', window.scrollY > 60);
}, { passive: true });

// ===== HAMBURGER MENU =====
const hamburger = document.getElementById('hamburger');
const nav = document.getElementById('nav');

hamburger.addEventListener('click', () => {
  hamburger.classList.toggle('open');
  nav.classList.toggle('open');
});

nav.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => {
    hamburger.classList.remove('open');
    nav.classList.remove('open');
  });
});

// ===== PARTICLE EFFECT =====
function createParticles() {
  const container = document.getElementById('particles');
  if (!container) return;
  for (let i = 0; i < 30; i++) {
    const p = document.createElement('div');
    p.className = 'particle';
    p.style.left = Math.random() * 100 + '%';
    p.style.top = (40 + Math.random() * 50) + '%';
    p.style.setProperty('--dur', (6 + Math.random() * 8) + 's');
    p.style.setProperty('--delay', (Math.random() * 8) + 's');
    container.appendChild(p);
  }
}

createParticles();

// ===== COUNT-UP ANIMATION =====
function countUp(el, target, duration = 1800) {
  let start = 0;
  const startTime = performance.now();
  function step(now) {
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const ease = 1 - Math.pow(1 - progress, 3);
    el.textContent = Math.floor(ease * target);
    if (progress < 1) requestAnimationFrame(step);
    else el.textContent = target;
  }
  requestAnimationFrame(step);
}

// ===== INTERSECTION OBSERVER =====
const io = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (!entry.isIntersecting) return;

    // Count-up for stats
    if (entry.target.classList.contains('stats__item')) {
      const numEl = entry.target.querySelector('.stats__num');
      const target = parseInt(entry.target.dataset.count, 10);
      countUp(numEl, target);
    }

    // Reveal animation
    if (entry.target.classList.contains('reveal')) {
      entry.target.classList.add('revealed');
    }

    io.unobserve(entry.target);
  });
}, { threshold: 0.2 });

document.querySelectorAll('.stats__item').forEach(el => io.observe(el));

// Add reveal class and observe
const revealTargets = [
  '.about__grid',
  '.features__card',
  '.discount__tier',
  '.contact__box',
  '.items__placeholder',
];

revealTargets.forEach(selector => {
  document.querySelectorAll(selector).forEach((el, i) => {
    el.classList.add('reveal');
    el.style.transitionDelay = (i * 0.08) + 's';
    io.observe(el);
  });
});

// ===== BACK TO TOP =====
const backToTop = document.getElementById('backToTop');

window.addEventListener('scroll', () => {
  backToTop.classList.toggle('visible', window.scrollY > 500);
}, { passive: true });

backToTop.addEventListener('click', () => {
  window.scrollTo({ top: 0, behavior: 'smooth' });
});

// ===== ITEM CATEGORY BUTTONS (visual only) =====
document.querySelectorAll('.items__cat-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.items__cat-btn').forEach(b => b.classList.remove('items__cat-btn--active'));
    btn.classList.add('items__cat-btn--active');
  });
});
