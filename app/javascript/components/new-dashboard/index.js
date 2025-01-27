import { useState, useEffect } from 'react';

export default function NewDashboard() {
    const [refreshKey, setRefreshKey] = useState(0);

    const refreshIframe = () => {
        setRefreshKey(prevKey => prevKey + 1);
    };

    useEffect(() => {
        // Call the refreshIframe function whenever needed
        refreshIframe();
    }, []); // Empty dependency array means this runs once on component mount

    return (
        <div>
            <iframe
                key={refreshKey}
                title="new-dashboard"
                src="https://frappe.erp.mmis.space:8444/insights/public/dashboard/9e0f5baebf8909968b951c685cb9f4adb8d45054d1760013d8b42ac4"
                width="100%"
                height="800px"
                frameBorder="0"
                allowTransparency
            />
        </div>
    );
}

NewDashboard.displayName = "NewDashboard";
