
function showPage(page) {
    const content = document.getElementById("content");

    const pages = {
        dashboard: `
            <h2>Tổng quan hệ thống</h2>
            <p>Chào mừng đến với hệ thống Phúc Long Mart.</p>
        `,
        affiliate: `
            <h2>Quản lý Affiliate</h2>
            <p>Chức năng quản lý thông tin KOL/KOC và Affiliate.</p>
        `,
        orders: `
            <h2>Quản lý đơn hàng</h2>
            <p>Chức năng theo dõi đơn hàng TikTok Affiliate.</p>
        `,
        commission: `
            <h2>Quản lý hoa hồng</h2>
            <p>Chức năng tính toán hoa hồng Affiliate.</p>
        `,
        reconcile: `
            <h2>Đối soát hoa hồng</h2>
            <p>Chức năng kiểm tra và so sánh số liệu hoa hồng.</p>
        `,
        payment: `
            <h2>Quản lý thanh toán</h2>
            <p>Chức năng theo dõi trạng thái thanh toán.</p>
        `
    };

    content.innerHTML = pages[page] || pages.dashboard;
}
