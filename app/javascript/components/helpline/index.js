import { useEffect } from 'react';
import { useHistory } from 'react-router-dom';

export default function Helpline() {
    const history = useHistory();
    const helplineUrl = "http://192.168.10.195/kpcpwc";

    useEffect(() => {
        if (helplineUrl) {
            window.open(helplineUrl, '_blank', 'noopener,noreferrer');
        }
        history.replace('/dashboards');
    }, [history, helplineUrl]);

    return null;
}

Helpline.displayName = "Helpline";