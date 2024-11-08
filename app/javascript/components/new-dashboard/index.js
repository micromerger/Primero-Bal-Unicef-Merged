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
                src="https://dashboard.primero.mmis.space:8443/insights/public/dashboard/652c6417146956036820f8db88aa33e643a28fb73012bad8db8ec560"
                width="100%"
                height="800px"
                frameBorder="0"
                allowTransparency
            />
        </div>
    );
}

NewDashboard.displayName = "NewDashboard";
