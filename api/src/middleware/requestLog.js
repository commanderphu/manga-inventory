const morgan = require('morgan');

// IP-Adressen nur gekürzt protokollieren (Datensparsamkeit, siehe Datenschutzerklärung):
// IPv4 ohne letzten Block (193.47.12.34 -> 193.47.12.0), IPv6 nur die ersten drei Blöcke (/48).
function anonymizeIp(ip) {
  if (!ip) return '-';
  const v4 = ip.match(/^(?:::ffff:)?(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}$/i);
  if (v4) return `${v4[1]}.0`;
  if (ip.includes(':')) {
    const head = ip.split('::')[0].split(':').filter(Boolean).slice(0, 3);
    return `${head.join(':')}::`;
  }
  return '-';
}

morgan.token('anon-ip', (req) => anonymizeIp(req.ip));

// Wie "combined", nur mit gekürzter IP
const FORMAT = ':anon-ip - :remote-user [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent"';

// Health-Checks (Uptime Kuma, Docker) machen sonst fast das ganze Log aus
const skipHealth = (req, res) => req.path === '/health' && res.statusCode < 400;

function requestLog(production) {
  return production
    ? morgan(FORMAT, { skip: skipHealth })
    : morgan('dev', { skip: skipHealth });
}

module.exports = { requestLog, anonymizeIp };
