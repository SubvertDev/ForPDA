function afterNavigate() {
    var regex = /\d{4}\/\d{2}\/\d{2}\/\d+\//;
    var result = window.location.href.match(regex);
    if (result !== null) {
        window.location.href = `forpda://article/${result}`;
    }
}
(document.body || document.documentElement).addEventListener('transitionend',
  function(event) {
    if (event.propertyName === 'width' && event.target.id === 'progress') {
        afterNavigate();
    }
}, true);

afterNavigate();
