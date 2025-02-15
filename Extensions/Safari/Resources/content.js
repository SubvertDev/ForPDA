function afterNavigate() {
    const titleElement = document.querySelector('h1');
    const title = titleElement.textContent.trim();
    
    const photoDiv = document.querySelector('div.photo');
    const imageElement = photoDiv.querySelector('img[itemprop="image"]');
    const imageUrlSource = imageElement.getAttribute('src');
    var imageUrl;
    if (imageUrlSource.includes('?')) {
        imageUrl = imageUrlSource.split('?')[0];
    } else {
        imageUrl = imageUrlSource;
    }
    
    var regex = /\d{4}\/\d{2}\/\d{2}\/\d+\//;
    var result = window.location.href.match(regex);
    if (result !== null) {
        window.location.href = `forpda://article/${result}?title=${title}&imageUrl=${imageUrl}`;
    }
}
(document.body || document.documentElement).addEventListener('transitionend',
  function(event) {
    if (event.propertyName === 'width' && event.target.id === 'progress') {
        afterNavigate();
    }
}, true);

afterNavigate();
