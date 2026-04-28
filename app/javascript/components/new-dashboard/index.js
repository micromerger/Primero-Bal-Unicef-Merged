import { useState, useEffect } from 'react';

export default function NewDashboard() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [dashboardUrl, setDashboardUrl] = useState(null);

  const locationToDashboardMap = {
    'BAL01': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/d4c113f98c46466a7e27fe9757e531785d945fdfdc86f8d8abd35256',
    'BAL02': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/88ab372fb351aeba97fd6a96e0577256a1b710ff84998b42cb8a0c2b',
    'BAL03': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/decd2f9ecc3fd7aaa0f8faebbfb2cb1e1be03099a219cc9699a26bd8',
    'BAL04': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/54d5120428b4e136b75393b75a33b2b2c183cbaefea87be65a2474ee',
    'BAL05': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/3cc6384b3c5aabf016a1b31cafb67ef44e125ae63a411091a9e222ea',
    'BAL06': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/1523bbe459295f4a1a442f5ad8d5cae2783f85075f5238180ec55ea8',
    'BAL07': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/6b1468da5d59c34e12b29c669f1e8266b48f00164052593407672409',
    'BAL08': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/25951c2825ae41348121b1bbe44004ae49d87fedb46665b7d916af66',
    'BAL09': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/07be32b4b1c66d0e5abf82d7127513e0776c9031166af1b5a00b11f3',
    'BAL10': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/8c805d815228889dc5b620fcb779ae4dc3c9892c21d57ee1aa63c9cf',
    'BAL11': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/2ceeb4eb79cc57ac3de600472c62d7b699e6bdcedb0ec8cd94cb03cf',
    'BAL12': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/3dc6f369eff9f227fa10e2783bf516c8b62c615680bd92ece275ace1',
    'BAL13': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/8ea3b13bf722f31c6e16af9e035a7684cc8a2d0af804324a236c81ef',
    'BAL14': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/b3ca6fa936c8ce32572ed7190771a149c3810cde3eaaaf86987e023d',
    'BAL15': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/ef92af6f26da6eea9ee07c43b502ff3e7e054be595456ffb387acd43',
    'BAL16': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/c93b77110bb5bb852977600289b959526bd1970c1db8aeafbe272867',
    'BAL17': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/6ec78ddaf4bbe22559de4007ba5e399369c536606cb260a968332671',
    'BAL18': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/1cac353c18a5e403285db33e43f6c2595ac71a25e262aea9e0ce60d5',
    'BAL19': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/73971d2fc37c7881bb5f78c2e1bbdc062a8d0c0bd2d92c83aeb7aa40',
    'BAL20': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/e0a4ad9d9177362e8eebbe8c31f9dc02df15e9ee274b3858a49464ba',
    'BAL21': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/f5892311b703e5219a586e4bfd0bacca32477dfe2c534a8834904d54',
    'BAL22': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/2a7486e8fa76d45eaaaec01918cdf2764fb591d6701c4f2de2bbb867',
    'BAL23': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/1818d22de3a3e6f7130b2c46739e735b6a0cf2ec608d8882d84e8136',
    'BAL24': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/89d2c7f70d6d79060a3d06cea6747c368aa5c1b00d0e1fc791cabee9',
    'BAL25': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/2c0d0940a9f7526273fbe6d362dac7a475b38dda6eb5ef0bdf76cdce',
    'BAL26': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/bd6d9d3ea29201c836ef6de545ae28e011b918e00eb980444d87db42',
    'BAL27': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/516d3bc2d7168b893c0525fcdf8a431ef443e8161e5fd09f1aa88690',
    'BAL28': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/20450a4f5d13e67d0879cc28b6df71a74ffda39c752a560e43da0124',
    'BAL29': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/a1c7954e96944e11a86038faac25cbacc4fe7388d09f2772dcaa8455',
    'BAL30': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/a53b626ef089134a530e46b8ea0bd85fe4fef53f2ab911eec1cbd9ae',
    'BAL31': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/6b0e10d62df9104b453c1343d348a499020947f1b3493778f8f7b7dd',
    'BAL32': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/81ebe8b78fb677089d4355155c77de177220080e461a59750ba183f7',
    'Default': 'https://bal.cpims.org.pk:8443/insights/public/dashboard/9fdfe4ff1ff7dd1150010264ddb06b4f564dbede98c7e9b77a0ad4af'
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