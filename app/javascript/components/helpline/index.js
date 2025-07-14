import { useEffect } from 'react';
import { useHistory } from 'react-router-dom';

export default function Helpline() {
    const history = useHistory();
    const helplineUrl = "https://cpims.kpcpwc.gov.pk/helpline/";

    useEffect(() => {
        if (helplineUrl) {
            window.open(helplineUrl, '_blank', 'noopener,noreferrer');
        }
        history.replace('/dashboards');
    }, [history, helplineUrl]);

    return null;
}

Helpline.displayName = "Helpline";