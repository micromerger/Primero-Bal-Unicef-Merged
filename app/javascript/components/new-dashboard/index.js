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
                src="https://dashboard-punjab.mmis.space/insights/public/dashboard/4e6246cfa261b836db58e3a2ecb9d76bc8e260ff3657a71380f17058"
                width="100%"
                height="740px"
                frameBorder="0"
                allowTransparency
            />
        </div>
    );
}

NewDashboard.displayName = "NewDashboard";
