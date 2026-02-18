// ========================================
// Gallery & Lightbox Functionality
// ========================================

let currentImageIndex = 0;
let galleryImages = [];

/**
 * Initialize gallery with images
 * @param {string} basePath - Base path to images folder
 * @param {Array} imageConfig - Array of objects with count, ext, and optional startFrom
 */
function initGallery(basePath, imageConfig) {
    const gallery = document.getElementById('gallery');
    if (!gallery) return;

    galleryImages = [];
    let imageIndex = 0;

    imageConfig.forEach(config => {
        const { count, ext, startFrom = 1 } = config;

        for (let i = 0; i < count; i++) {
            const imgNumber = startFrom + i;
            const paddedNumber = String(imgNumber).padStart(3, '0');
            const imgPath = `${basePath}${paddedNumber}.${ext}`;

            // Create gallery item
            const item = document.createElement('div');
            item.className = 'gallery-item';
            item.dataset.index = imageIndex;

            const img = document.createElement('img');
            img.src = imgPath;
            img.alt = `Image ${paddedNumber}`;
            img.loading = 'lazy';

            // Handle image load error
            img.onerror = function() {
                this.parentElement.style.display = 'none';
            };

            item.appendChild(img);
            gallery.appendChild(item);

            // Store image info
            galleryImages.push({
                src: imgPath,
                alt: img.alt,
                index: imageIndex
            });

            imageIndex++;
        }
    });

    // Add click listeners to gallery items
    const items = gallery.querySelectorAll('.gallery-item');
    items.forEach(item => {
        item.addEventListener('click', function() {
            const index = parseInt(this.dataset.index);
            openLightbox(index);
        });
    });

    // Initialize lightbox controls
    initLightbox();
}

/**
 * Initialize lightbox controls
 */
function initLightbox() {
    const lightbox = document.getElementById('lightbox');
    const closeBtn = document.querySelector('.lightbox-close');
    const prevBtn = document.querySelector('.lightbox-prev');
    const nextBtn = document.querySelector('.lightbox-next');

    if (!lightbox) return;

    // Close button
    closeBtn.addEventListener('click', closeLightbox);

    // Previous button
    prevBtn.addEventListener('click', () => {
        currentImageIndex = (currentImageIndex - 1 + galleryImages.length) % galleryImages.length;
        updateLightboxImage();
    });

    // Next button
    nextBtn.addEventListener('click', () => {
        currentImageIndex = (currentImageIndex + 1) % galleryImages.length;
        updateLightboxImage();
    });

    // Close on background click
    lightbox.addEventListener('click', function(e) {
        if (e.target === this) {
            closeLightbox();
        }
    });

    // Keyboard navigation
    document.addEventListener('keydown', function(e) {
        if (!lightbox.classList.contains('active')) return;

        switch(e.key) {
            case 'Escape':
                closeLightbox();
                break;
            case 'ArrowLeft':
                prevBtn.click();
                break;
            case 'ArrowRight':
                nextBtn.click();
                break;
        }
    });
}

/**
 * Open lightbox with specific image
 * @param {number} index - Index of image to display
 */
function openLightbox(index) {
    const lightbox = document.getElementById('lightbox');
    currentImageIndex = index;
    updateLightboxImage();
    lightbox.classList.add('active');
    document.body.style.overflow = 'hidden';
}

/**
 * Close lightbox
 */
function closeLightbox() {
    const lightbox = document.getElementById('lightbox');
    lightbox.classList.remove('active');
    document.body.style.overflow = '';
}

/**
 * Update lightbox image
 */
function updateLightboxImage() {
    const img = document.getElementById('lightbox-img');
    const counter = document.getElementById('lightbox-counter');
    const downloadBtn = document.getElementById('lightbox-download');

    const currentImage = galleryImages[currentImageIndex];

    img.src = currentImage.src;
    img.alt = currentImage.alt;
    counter.textContent = `${currentImageIndex + 1} / ${galleryImages.length}`;
    downloadBtn.href = currentImage.src;
    downloadBtn.download = currentImage.src.split('/').pop();
}

/**
 * Preload adjacent images for smooth navigation
 */
function preloadAdjacentImages() {
    const prevIndex = (currentImageIndex - 1 + galleryImages.length) % galleryImages.length;
    const nextIndex = (currentImageIndex + 1) % galleryImages.length;

    [prevIndex, nextIndex].forEach(index => {
        const img = new Image();
        img.src = galleryImages[index].src;
    });
}

// Touch support for mobile swipe
let touchStartX = 0;
let touchEndX = 0;

document.addEventListener('DOMContentLoaded', function() {
    const lightbox = document.getElementById('lightbox');
    if (!lightbox) return;

    lightbox.addEventListener('touchstart', function(e) {
        touchStartX = e.changedTouches[0].screenX;
    }, false);

    lightbox.addEventListener('touchend', function(e) {
        touchEndX = e.changedTouches[0].screenX;
        handleSwipe();
    }, false);
});

function handleSwipe() {
    const swipeThreshold = 50;
    const diff = touchStartX - touchEndX;

    if (Math.abs(diff) > swipeThreshold) {
        if (diff > 0) {
            // Swipe left - next image
            document.querySelector('.lightbox-next').click();
        } else {
            // Swipe right - previous image
            document.querySelector('.lightbox-prev').click();
        }
    }
}
