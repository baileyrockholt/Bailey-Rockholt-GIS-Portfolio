# Bailey Rockholt — Environmental GIS & Spatial Data Analysis

Static portfolio for the existing GitHub Pages repository. No framework or build dependency is required.

## Pages and assets

- index.html: homepage, projects, current work, background, skills, résumé status, contact.
- california-wildfire.html: R and ArcGIS Online case study with all four original charts.
- lake-tahoe.html: ArcGIS Pro map, workflow, methodology, and limitations.
- clarkia-habitat.html: botanical mapping case study and workflow.
- style.css and site.js: responsive styling and accessible mobile navigation.

All nine original images remain at the repository root, unchanged. Map previews retain their full composition. Case studies offer original-resolution viewing and image downloads. Navigation works without JavaScript; the enhanced mobile menu supports Escape and expanded-state announcements. Reduced-motion preferences are respected.

## Validate and preview

Run node check-site.cjs and node --check site.js. Serve this directory using a static HTTP server, or open index.html directly. No build step is required. Relative paths support deployment beneath /Bailey-Rockholt-GIS-Portfolio/.

## Update content

Edit the HTML pages directly. Keep source image names or update their references. Retain documentation limitations until the source data, citations, and analysis details are supplied. Do not infer causal findings, completed research, or publication status from map exports.

The consolidated environmental GIS résumé is in assets/Bailey_Rockholt_Environmental_GIS_Resume.pdf. Confirmed dates: State Parks August 2026–Present; B.S. December 2022; CMS ended August 2026; USDA remains active. It omits private phone/address information for public portfolio use. The original résumé variants are not committed.

Supplied R and Python scripts are retained in code/ with setup instructions, interpretation limits, and a generated Python example. The R script is a recovered workflow, reviewed but not rerun because its raw CSV and the R runtime were unavailable. The Python tool is a separately labeled exploratory prototype, not an official agency product or validated agronomic model. See crop-suitability.html.

## Public map verification

Verified without authentication on November 7, 2026 through ArcGIS item metadata and item data:

- https://arcg.is/1vK0ru3 resolves to web map 9f0e311728474400ae384e9b4a210f7d, titled California Wildfire Analysis (2013-2019), owner baileyrockholt, access public. The layer configuration includes county boundaries and the wildfire analysis feature service.
- Web map 8f87df10fd2b419f9c45ee53890ff7ae is California Recreation and Conservation Explorer, owner baileyrockholt, access public. Layers include public lands, critical habitat, recreation, and current wildfire groups. This map appears separately from the three case studies.

Public item availability does not guarantee that every third-party layer will remain available. No interactive map was substituted for Tahoe or Clarkia. Reference portfolio metadata was inspected for context; its visual design was not copied.

## Validation performed

Five pages and 126 local references passed file/anchor, unique-id, image-alt, viewport, and heading checks. JavaScript syntax and git whitespace checks passed. Desktop homepage and 390px mobile homepage and Tahoe case study were inspected in the browser. Mobile menu expansion and Escape dismissal worked. The full-resolution and download destinations are original image files.

## Review and deployment

Based on main commit 4c952d2. Local development branch: portfolio/environmental-gis-case-studies. Do not merge or deploy to main without Bailey's approval.

GitHub installation access is now verified. The development branch and pull request #1 are available for review. Do not merge or deploy without Bailey's approval.

## Case study refinements

The wildfire page includes the verified public ArcGIS map in a responsive frame with a direct-link fallback. Original chart captions now explain the visible annual/monthly peaks and county rankings, and correct the distinction between acres burned and ecological burn severity. Tahoe and Clarkia workflow captions describe the visible layer/symbology evidence and identify remaining source-data questions.

The ArcGIS embedded wildfire map now renders in the local browser with map attribution and zoom controls visible. Desktop and 390px mobile views were checked, including the new Python project page; a mobile grid-overflow issue was corrected and the page width now fits the viewport. The résumé returns HTTP 200 as application/pdf. Static link, syntax, and Python prototype checks pass. The two-page résumé PDF was rendered and both pages visually inspected.

## Preview review

A complete offline preview ZIP accompanies this revision. Extract it and open index.html. Maps require internet access; the rest of the site and résumé work locally. Do not merge or deploy until Bailey has reviewed the preview.
