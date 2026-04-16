---
title: Distributions
---

# Supported Distributions

Below is the list of Linux distributions and operating systems supported by DistroHopper. This list is automatically updated from the [distributionhub](https://github.com/oSoWoSo/distributionhub) project.

<link rel="stylesheet" href="lib/bootstrap.min.css">
<link rel="stylesheet" href="distros.css">

<script src="distros.js"></script>

<div class="search-container mb-4">
    <div class="search-filter-group">
        <div class="search-input-wrapper">
            <input type="text" id="distroSearch" class="form-control" placeholder="Search distributions..." aria-label="Search distributions">
        </div>
        <div class="filter-buttons">
            <button class="btn btn-outline-info btn-sm filter-btn" data-filter="beginner">Beginner</button>
            <button class="btn btn-outline-info btn-sm filter-btn" data-filter="advanced">Advanced</button>
            <button class="btn btn-outline-info btn-sm filter-btn" data-filter="lightweight">Lightweight</button>
        </div>
    </div>
</div>

<div class="row" id="distroList"></div>

<style>
/* Override for dark background */
body {
    background-color: #1a1a1a;
    color: #ffffff;
}
.search-container .form-control {
    background-color: #2d2d2d;
    border: 1px solid #444;
    color: #fff;
}
.search-container .form-control::placeholder {
    color: #aaa;
}
.filter-btn {
    background-color: transparent;
    border-color: #8CFFFA;
    color: #8CFFFA;
}
.filter-btn:hover, .filter-btn.active {
    background-color: #8CFFFA;
    color: #1a1a1a;
}
</style>

<script>
document.addEventListener("DOMContentLoaded", function() {
    const distroList = document.getElementById('distroList');
    const distroSearch = document.getElementById('distroSearch');
    const filterButtons = document.querySelectorAll('.filter-btn');
    
    let currentFilter = 'all';
    let searchTerm = '';
    
    // Get distributions from window.distributions
    const distributions = window.distributions || [];
    
    function createDistroCard(distro) {
        const cleanVersion = distro.version.replace(/\sx86_64/i, '');
        // Use default icon if not found or just use the path as-is from distributionhub
        const iconSrc = distro.icon && distro.icon.endsWith('.png') ? distro.icon : 'img/distro/default-distro.png';
        
        const card = document.createElement('div');
        card.className = 'col-md-4 mb-4 distro-card-wrapper';
        card.setAttribute('data-category', distro.category || 'other');
        card.setAttribute('data-name', distro.name.toLowerCase());
        
        card.innerHTML = `
            <div class="card h-100">
                <div class="card-img-container">
                    <img src="${iconSrc}" class="card-img-top" alt="${distro.name} logo" loading="lazy">
                </div>
                <div class="card-body d-flex flex-column">
                    <h5 class="card-title">
                        ${distro.websiteLink ? `<a href="${distro.websiteLink}" class="distro-title-link" target="_blank" rel="noopener">` : ''}
                        <strong>${distro.name}</strong>
                        ${distro.websiteLink ? '</a>' : ''}
                    </h5>
                    <div class="card-text distro-version">
                        <strong>Version:</strong> ${cleanVersion}
                    </div>
                    <p class="card-text flex-grow-1">${distro.description || ''}</p>
                    <div class="mt-auto">
                        <a href="${distro.downloadLink || '#'}" class="btn btn-download flex-grow-1" target="_blank" rel="noopener">
                            <i class="fas fa-download me-2"></i>Download
                        </a>
                    </div>
                </div>
            </div>
        `;
        
        return card;
    }
    
    function renderDistros() {
        distroList.innerHTML = '';
        
        const filtered = distributions.filter(distro => {
            const matchesCategory = currentFilter === 'all' || (distro.category || 'other') === currentFilter;
            const matchesSearch = distro.name.toLowerCase().includes(searchTerm) || 
                (distro.description && distro.description.toLowerCase().includes(searchTerm));
            return matchesCategory && matchesSearch;
        });
        
        filtered.forEach(distro => {
            distroList.appendChild(createDistroCard(distro));
        });
    }
    
    // Search functionality
    distroSearch.addEventListener('input', function(e) {
        searchTerm = e.target.value.toLowerCase();
        renderDistros();
    });
    
    // Filter buttons
    filterButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const filter = this.getAttribute('data-filter');
            currentFilter = filter === currentFilter ? 'all' : filter;
            
            filterButtons.forEach(b => b.classList.remove('active'));
            if (currentFilter !== 'all') {
                this.classList.add('active');
            }
            renderDistros();
        });
    });
    
    // Initial render
    renderDistros();
});
</script>