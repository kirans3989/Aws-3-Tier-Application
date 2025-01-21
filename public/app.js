// Frontend JavaScript (served via CloudFront in production)
async function addItem() {
    const input = document.getElementById('newItem');
    const name = input.value.trim();
    
    if (!name) return;

    try {
        const response = await fetch('/api/items', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ name })
        });

        if (!response.ok) throw new Error('Failed to add item');
        
        input.value = '';
        await loadItems();
    } catch (error) {
        console.error('Error:', error);
    }
}

async function loadItems() {
    try {
        const response = await fetch('/api/items');
        const items = await response.json();
        
        const itemsList = document.getElementById('itemsList');
        itemsList.innerHTML = items
            .map(item => `<div class="item">${item.name}</div>`)
            .join('');
    } catch (error) {
        console.error('Error:', error);
    }
}