import { useState, useEffect } from 'react';

export default function NewDashboard() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [dashboardUrl, setDashboardUrl] = useState(null);

  const locationToDashboardMap = {
    'LAR01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/99a071c001e2bb3017c4fddae06aaf00688b03b2dac25783190e6e30',
    'KASH01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/27b13285e5a0aa2bf14a8a973cef52257eeeaa0fba19284561cad36a',
    'SHI01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/d5abefab3275773422b5d23211019d09cea7a142c255b9d5a5de8bf6',
    'JAC01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/02c141a2849b7499012b3df7227e3b19113086d41dee563ed8ebe56d',
    'KS01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/5324edafd36ac748b83c713641a2167dc8782ba04400fcf64cf086ac',
    'SUK01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/f230e8b3502cf0b8b22a33af6a008dd372f5f937664be17a8df95118',
    'GT01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/bd355e285d26f02d5a7ebb09bbb75a1edc53f9805922377c9a236310',
    'KP01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/623e0c8e6328182e570a195194083dea8d756e8841757bbb066678d5',
    'SB01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/1cb276de7085d8e425c5449a7cd1d4f6373b1ef5566f92ea0bc37b06',
    'NF01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/c8951e4eac476cf4d8dcdbb4092975a81e16d37555fe409f58348b7a',
    'SG01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/85744d41e05e0919658ef08712b80444e4a7aa4000e7bf6dd967334c',
    'HB01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/99fd839c0fe915725dc10f623dd391406886957bc4947fc5f00fa1fb',
    'JM01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/901a32c850c3fc3ce9bdbd8e792ab7477374e0c98571f3fa65c80603',
    'DD01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/ecfdcd10946a60480718ab64faa6f52beea3d2dc1b00a14335da2b20',
    'MT01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/879c11f5dd2ac52775035d49f773a7bbe18c591ec959645a5f0e5c1e',
    'TA01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/a8e572dcacefda2a435bc5ddc8ed6a738b16424890c259f277942a09',
    'TMK01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/2050b6a82164cc49a4d3950d37afdf529e81b43e15483c5273a113ff',
    'BD01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/e0526403e53daf6211ac5fa93c904072de86ce1ddd672ea905d93402',
    'TT01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/0b037db72ec548dd749afe6ec3c11c8a1459883312da83921803940b',
    'SJ01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/c8aa227623f3db196540cc35ee9bb38d47fd6ec15655d2eb8acb036c',
    'MPK01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/6389925424a8de834e685155788a774a5fe8a6d14871417269bea964',
    'TPK01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/06b0ecf474f2cec0123c047b578cd5e85c14f28f37b710da2d7dd5d5',
    'UK01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/5684b550e069bb9fc5f413a63b229268fc14b318fb35677d50865569',
    'KE01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/be1017c1e04988bf03ec697d669ab9b4679d23f3c9a49c74b33a86c1',
    'KW01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/88b2221d695ae1a81c1332633783cc99032e92c05f53a60a4c13d438',
    'KS1': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/3db1001dd8dc4c51acaab28946b9750bc25a4612767eec002c3a5509',
    'KC01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/019b464acc4b9a2c3a0d6c27e036122ddfa80b4ad0686feb0fffe4f5',
    'ML01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/ab39fdeebd30333aca53dabaf19e9b14de9410784d05e013d1b839fe',
    'KRG01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/9b40fbaeb2785280162954915e9bb929fbe70169132cb282ffa9be58',
    'KM01': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/6afc00a9eab082fde4d301b17781118086331cb7ea8f1db3341603c6',
    'Default': 'https://sindh.cpims.org.pk:8443/insights/public/dashboard/5a34c938e2ae0f00d8a1d77afaa1c2e431c40384ffcfff1c5cbe09bc'
  };

  const refreshIframe = () => {
    setRefreshKey(prevKey => prevKey + 1);
  };

  useEffect(() => {
    fetch('/api/v2/users/current', {
      credentials: 'include'
    })
      .then(res => res.json())
      .then(data => {
        const userLocation = data.parent_location_code;
        const url = locationToDashboardMap[userLocation?.trim()] || locationToDashboardMap['Default'];
        setDashboardUrl(url);
        refreshIframe();
      })
      .catch(err => {
        console.error('Failed to fetch user info:', err);
        setDashboardUrl(locationToDashboardMap['Default']);
      });
  }, []);

  if (!dashboardUrl) return <div></div>;

  return (
    <div>
      <iframe
        key={refreshKey}
        title="user-location-dashboard"
        src={dashboardUrl}
        width="100%"
        height="760px"
        frameBorder="0"
        allowTransparency
      />
    </div>
  );
}

NewDashboard.displayName = "NewDashboard";