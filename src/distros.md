---
title: Distributions
---

# Supported Distributions

Below is the list of Linux distributions and operating systems supported by DistroHopper. This list is automatically updated from the [distributionhub](https://github.com/oSoWoSo/distributionhub) project.

<script src="distros.js"></script>

<div id="distributions-gallery"></div>

<script>
document.addEventListener("DOMContentLoaded", function() {
  const gallery = document.getElementById("distributions-gallery");
  // Handle either `window.distributions` or global `distributions`
  const distributions = window.distributions || (typeof distributions !== 'undefined' ? distributions : null);
  
  if (!gallery || !distributions || !Array.isArray(distributions)) {
    console.warn("Distributions data not found");
    return;
  }

  // Group by category
  const categories = {};
  distributions.forEach(distro => {
    const cat = distro.category || "other";
    if (!categories[cat]) categories[cat] = [];
    categories[cat].push(distro);
  });

  // Create section for each category
  Object.keys(categories).sort().forEach(category => {
    const section = document.createElement("section");
    section.className = "distro-category";
    
    const heading = document.createElement("h2");
    heading.textContent = category.charAt(0).toUpperCase() + category.slice(1);
    section.appendChild(heading);
    
    const grid = document.createElement("div");
    grid.className = "distro-grid";
    
    categories[category].forEach(distro => {
      const card = document.createElement("div");
      card.className = "distro-card";
      
      const title = document.createElement("h3");
      title.textContent = distro.name;
      card.appendChild(title);
      
      const version = document.createElement("p");
      version.className = "version";
      version.textContent = distro.version;
      card.appendChild(version);
      
      if (distro.description) {
        const desc = document.createElement("p");
        desc.className = "description";
        desc.textContent = distro.description;
        card.appendChild(desc);
      }
      
      if (distro.websiteLink) {
        const link = document.createElement("a");
        link.href = distro.websiteLink;
        link.textContent = "Website";
        link.target = "_blank";
        card.appendChild(link);
      }
      
      grid.appendChild(card);
    });
    
    section.appendChild(grid);
    gallery.appendChild(section);
  });
});
</script>