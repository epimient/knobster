/* ─────────────────────────────────────────────
   Knobster — Copy button + interactions
   ───────────────────────────────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  const copyBtn = document.getElementById('copy-btn');
  const codeEl = document.getElementById('install-code');

  if (!copyBtn || !codeEl) return;

  copyBtn.addEventListener('click', async () => {
    const text = codeEl.textContent.trim();

    try {
      await navigator.clipboard.writeText(text);

      const original = copyBtn.textContent;
      copyBtn.textContent = '✔ Copied';
      copyBtn.classList.add('copied');

      setTimeout(() => {
        copyBtn.textContent = original;
        copyBtn.classList.remove('copied');
      }, 1800);
    } catch {
      // Fallback: select text
      const range = document.createRange();
      range.selectNodeContents(codeEl);
      const selection = window.getSelection();
      selection?.removeAllRanges();
      selection?.addRange(range);

      copyBtn.textContent = '✔ Selected';
      copyBtn.classList.add('copied');

      setTimeout(() => {
        copyBtn.textContent = 'Copy';
        copyBtn.classList.remove('copied');
      }, 1800);
    }
  });
});
