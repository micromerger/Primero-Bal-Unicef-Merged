import { useEffect } from 'react';
import { useHistory } from 'react-router-dom';

export default function Integrateddashboard() {
    const history = useHistory();
    const integrateddashboardUrl = "https://dashboard.kpcpwc.gov.pk/";

    useEffect(() => {
        if (integrateddashboardUrl) {
            window.open(integrateddashboardUrl, '_blank', 'noopener,noreferrer');
        }
        history.replace('/dashboards');
    }, [history, integrateddashboardUrl]);

    return null;
}

Integrateddashboard.displayName = "Integrateddashboard";