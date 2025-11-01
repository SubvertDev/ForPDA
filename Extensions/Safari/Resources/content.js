function afterNavigate() {
    const path = window.location.pathname.split('/').filter(Boolean);
    const firstPart = path[0];

    let caseType;

    if (/^\d+$/.test(firstPart)) {
        caseType = 'article';
    } else {
        caseType = firstPart;
    }

    switch (caseType) {
        case 'article': {
            const titleElement = document.querySelector('h1');
            if (!titleElement) break;

            const title = titleElement.textContent.trim();

            let imageUrl = null;

            // New format: <link rel="image_src" href="...">
            const linkImage = document.querySelector('link[rel="image_src"]');
            if (linkImage && linkImage.getAttribute('href')) {
                imageUrl = linkImage.getAttribute('href');
            } else {
                // Fallback: old format <div class="photo"><img itemprop="image" src="...">
                const photoDiv = document.querySelector('div.photo');
                if (photoDiv) {
                    const imageElement = photoDiv.querySelector('img[itemprop="image"]');
                    if (imageElement) {
                        const imageUrlSource = imageElement.getAttribute('src');
                        imageUrl = imageUrlSource.includes('?')
                            ? imageUrlSource.split('?')[0]
                            : imageUrlSource;
                    }
                }
            }

            if (!imageUrl) break;

            const regex = /\d{4}\/\d{2}\/\d{2}\/\d+\//;
            const result = window.location.href.match(regex);

            if (result !== null) {
                window.location.href = `forpda://article/${result}?title=${encodeURIComponent(title)}&imageUrl=${encodeURIComponent(imageUrl)}`;
            }
            break;
        }

        case 'forum': {
            const url = new URL(window.location.href);
            const params = url.searchParams;

            // https://4pda.to/forum/index.php?act=idx - base page, not redirecting
            // https://4pda.to/forum/index.php?showforum=140

            if (params.has('showforum')) {
                const forumId = params.get('showforum');
                let forumUrl = `forpda://forum/${forumId}`;

                // Append st if present
                if (params.has('st')) {
                    forumUrl += `?st=${params.get('st')}`;
                }

                window.location.href = forumUrl;
                break;
            }

            // https://4pda.to/forum/index.php?showtopic=1104159
            // https://4pda.to/forum/index.php?showtopic=1104159&st=20
            if (params.has('showtopic')) {
                const topicId = params.get('showtopic');
                let topicUrl = `forpda://topic/${topicId}`;

                if (params.has('st')) {
                    topicUrl += `?st=${params.get('st')}`;
                }

                window.location.href = topicUrl;
                break;
            }
            
            // https://4pda.to/forum/index.php?act=announce&f=140&st=238
            if (params.get('act') === 'announce') {
                const forumId = params.get('f');
                let announceUrl = `forpda://announce/${forumId}`;

                if (params.has('st')) {
                    announceUrl += `?st=${params.get('st')}`;
                }

                window.location.href = announceUrl;
                break;
            }
            
            // https://4pda.to/forum/index.php?showuser=3640948
            if (params.has('showuser')) {
                const userId = params.get('showuser');
                let forumUrl = `forpda://user/${userId}`;
                
                window.location.href = forumUrl;
                break;
            }

            console.log('Forum page detected but no showforum/showtopic/announce/showuser parameter found:', window.location.href);
            break;
        }

        default: {
            console.log(`No handler for first path part: ${firstPart}`);
        }
    }
}

(document.body || document.documentElement).addEventListener(
    'transitionend',
    function (event) {
        if (event.propertyName === 'width' && event.target.id === 'progress') {
            afterNavigate();
        }
    },
    true
);

afterNavigate();
