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
                src="https://www.punjab.cpims.org.pk:8443/insights/public/dashboard/5df1cfe2d344de531eafcec13bd0600b69072d9d080c547909729e5f"
                width="100%"
                height="740px"
                frameBorder="0"
                allowTransparency
            />
        </div>
    );
}

NewDashboard.displayName = "NewDashboard";
