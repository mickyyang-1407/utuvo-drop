document.documentElement.classList.add('js');
const screenshot = document.querySelector('[data-app-screenshot]');
const toggle = document.querySelector('.theme-toggle');
const buttons = document.querySelectorAll('[data-mode]');
function setTheme(mode) {
  document.documentElement.dataset.theme = mode;
  screenshot.src = screenshot.dataset[mode];
  screenshot.alt = screenshot.dataset[mode + 'Alt'];
  buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.mode === mode)));
  toggle.textContent = mode === 'dark' ? toggle.dataset.light : toggle.dataset.dark;
  toggle.setAttribute('aria-label', mode === 'dark' ? toggle.dataset.lightLabel : toggle.dataset.darkLabel);
}
buttons.forEach(button => button.addEventListener('click', () => setTheme(button.dataset.mode)));
toggle.addEventListener('click', () => setTheme(document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark'));
setTheme('light');
