const hydrateHTML = (cl, newInnerHTML) => [...document.getElementsByClassName(cl)]
    .forEach(el => {
        el.innerHTML = newInnerHTML;
    });