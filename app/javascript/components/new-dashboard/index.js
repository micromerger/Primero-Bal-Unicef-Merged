import { useState, useEffect, useCallback, useRef } from "react";
import Chart from "chart.js";

import css from "./styles.css";

const MONTH_NAMES = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function formatFallbackLabel(key) {
  return String(key || "")
    .replace(/_[a-f0-9]{7}$/, "")
    .replace(/__/g, " - ")
    .replace(/_/g, " ")
    .replace(/\b\w/g, l => l.toUpperCase());
}

async function fetchLookupMap(lookupId, fetchOptions) {
  try {
    const res = await fetch(`/api/v2/lookups/${lookupId}`, fetchOptions);

    if (!res.ok) {
      return {};
    }
    const json = await res.json();
    const values = json?.data?.values || [];
    const map = {};

    values.forEach(v => {
      if (!v || !v.id) {
        return;
      }
      let label = "";

      if (typeof v.display_text === "string") {
        label = v.display_text;
      } else if (v.display_text && typeof v.display_text === "object") {
        label = v.display_text.en || v.display_text["en-US"] || Object.values(v.display_text).find(Boolean) || v.id;
      } else {
        label = v.id;
      }
      map[v.id] = String(label || "").trim();
    });

    return map;
  } catch (_err) {
    return {};
  }
}

function toArray(val) {
  if (Array.isArray(val)) {
    return val;
  }
  if (val) {
    return [val];
  }

  return [];
}

const GENDER_COLORS = ["#00c0f0", "#f02fc2", "#8b5cf6", "#10b981", "#f59e0b", "#ec4899", "#64748b"];

const NATURE_COLORS = ["#ef4444", "#f59e0b", "#10b981", "#3b82f6", "#8b5cf6", "#64748b"];

const DIAGNOSED_COLORS = ["#0284c7", "#10b981", "#f59e0b", "#f02fc2", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b"];

const UNDIAGNOSED_COLORS = ["#6366f1", "#14b8a6", "#f97316", "#d946ef", "#3b82f6", "#84cc16", "#e11d48", "#a855f7"];

const INCIDENT_LOCATION_COLORS = [
  "#3b82f6",
  "#10b981",
  "#f59e0b",
  "#f02fc2",
  "#8b5cf6",
  "#06b6d4",
  "#ec4899",
  "#14b8a6",
  "#e11d48",
  "#64748b"
];

const CARE_ARRANGEMENT_COLORS = [
  "#0ea5e9",
  "#84cc16",
  "#f97316",
  "#a855f7",
  "#00c0f0",
  "#eab308",
  "#d946ef",
  "#6366f1",
  "#22c55e",
  "#94a3b8"
];

const MARITAL_STATUS_COLORS = ["#00c0f0", "#f02fc2", "#f59e0b", "#10b981", "#8b5cf6"];

const NATIONALITY_COLORS = ["#0284c7", "#10b981", "#f59e0b", "#f02fc2", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b"];

const EDUCATION_LABELS = {
  true: "Yes",
  false: "No",
  yes: "Yes",
  no: "No"
};

function formatEducationLabel(key) {
  const s = String(key).toLowerCase().trim();

  if (EDUCATION_LABELS[s]) {
    return EDUCATION_LABELS[s];
  }

  return String(key || "")
    .replace(/_/g, " ")
    .replace(/\b\w/g, l => l.toUpperCase());
}

const EDUCATION_COLORS = ["#10b981", "#ef4444"];

const LANGUAGE_COLORS = ["#00c0f0", "#f02fc2", "#f59e0b", "#10b981", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b"];

const RELIGION_COLORS = ["#10b981", "#f59e0b", "#0284c7", "#f02fc2", "#8b5cf6", "#06b6d4", "#ec4899", "#64748b"];

const AGE_GROUP_DEFINITIONS = [
  { key: "0-5", label: "0-5" },
  { key: "6-9", label: "6-9" },
  { key: "10-13", label: "10-13" },
  { key: "14-18", label: "14-18" },
  { key: "18+", label: "18+" },
  { key: "Unknown", label: "Unknown" }
];

function getAgeGroup(ageVal) {
  if (ageVal === null || ageVal === undefined || ageVal === "") {
    return "Unknown";
  }

  const age = Number(ageVal);

  if (Number.isNaN(age) || age < 0) {
    return "Unknown";
  }

  if (age <= 5) {
    return "0-5";
  }
  if (age <= 9) {
    return "6-9";
  }
  if (age <= 13) {
    return "10-13";
  }
  if (age <= 18) {
    return "14-18";
  }

  return "18+";
}

const WORKFLOW_DEFINITIONS = [
  { key: "new", label: "New" },
  { key: "assessment", label: "Assessment" },
  { key: "case_plan", label: "Individual Rehabilitation Program" },
  { key: "service_provision", label: "Service Provision" },
  { key: "services_implemented", label: "Service Implemented" }
];

function formatMonthYear(ymStr) {
  if (!ymStr || ymStr.length < 7) {
    return ymStr || "";
  }
  const parts = ymStr.split("-");
  const year = parts[0];
  const monthIdx = parseInt(parts[1], 10) - 1;
  const monthName = MONTH_NAMES[monthIdx] || parts[1];

  return `${monthName} ${year}`;
}

function getDisplayCount(loading, count) {
  if (loading) {
    return "...";
  }

  if (count !== null && count !== undefined) {
    return count;
  }

  return "--";
}

function formatPieLabelLines(label, maxChars = 15) {
  if (!label || label.length <= maxChars) {
    return [label || ""];
  }

  const words = label.split(/\s+/);

  if (words.length <= 1) {
    return [label.length > maxChars ? `${label.substring(0, maxChars - 1)}…` : label];
  }

  const line1 = [];
  const line2 = [];
  let currentLine = 1;

  for (let i = 0; i < words.length; i += 1) {
    const word = words[i];

    if (currentLine === 1) {
      const candidate = line1.length === 0 ? word : `${line1.join(" ")} ${word}`;

      if (candidate.length <= maxChars || line1.length === 0) {
        line1.push(word);
      } else {
        line2.push(word);
        currentLine = 2;
      }
    } else {
      line2.push(word);
    }
  }

  const l1 = line1.join(" ");
  let l2 = line2.join(" ");

  if (l2.length > maxChars) {
    l2 = `${l2.substring(0, maxChars - 1)}…`;
  }

  return l2 ? [l1, l2] : [l1];
}

const inlinePieLabelsPlugin = {
  afterDraw: chart => {
    if (chart.config.type !== "pie") {
      return;
    }

    const { ctx } = chart;
    const meta = chart.getDatasetMeta(0);

    if (!meta || !meta.data) {
      return;
    }

    const dataset = chart.data.datasets[0];

    meta.data.forEach((element, index) => {
      const count = dataset.data[index];

      if (!count || count === 0) {
        return;
      }

      if (!element || !element._view) {
        return;
      }

      const { outerRadius, x, y, startAngle, endAngle } = element._view;

      if (!outerRadius || outerRadius <= 0) {
        return;
      }

      const midAngle = (startAngle + endAngle) / 2;
      const cos = Math.cos(midAngle);
      const sin = Math.sin(midAngle);

      const labelName = chart.data.labels[index] || "";
      const lines = formatPieLabelLines(labelName, 15);

      const sliceColor = (Array.isArray(dataset.backgroundColor) && dataset.backgroundColor[index]) || "#475569";

      const startRadius = outerRadius * 0.88;
      const startX = x + cos * startRadius;
      const startY = y + sin * startRadius;

      const endRadius = outerRadius + 14;
      const endX = x + cos * endRadius;
      const endY = y + sin * endRadius;

      ctx.save();

      // Draw arrow pointer line from slice towards label
      ctx.beginPath();
      ctx.moveTo(startX, startY);
      ctx.lineTo(endX, endY);
      ctx.strokeStyle = sliceColor;
      ctx.lineWidth = 1.5;
      ctx.stroke();

      // Draw directional arrowhead at the tip pointing outward
      const headLen = 5;
      const wingAngle = Math.PI / 7;
      const angle1 = midAngle - wingAngle;
      const angle2 = midAngle + wingAngle;

      ctx.beginPath();
      ctx.moveTo(endX, endY);
      ctx.lineTo(endX - headLen * Math.cos(angle1), endY - headLen * Math.sin(angle1));
      ctx.lineTo(endX - headLen * Math.cos(angle2), endY - headLen * Math.sin(angle2));
      ctx.closePath();
      ctx.fillStyle = sliceColor;
      ctx.fill();

      // Draw label text outside slice with modern legible font
      ctx.font = "600 11px -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
      ctx.fillStyle = "#1e293b";

      const lineHeight = 13;
      const totalHeight = lines.length * lineHeight;
      const maxLineWidth = Math.max(...lines.map(l => ctx.measureText(l).width));

      let textX;
      let textY;

      if (Math.abs(cos) < 0.3) {
        textX = endX;
        ctx.textAlign = "center";
        if (sin < 0) {
          textY = endY - 4 - totalHeight;
        } else {
          textY = endY + 6;
        }
      } else {
        if (cos > 0) {
          textX = endX + 5;
          ctx.textAlign = "left";
        } else {
          textX = endX - 5;
          ctx.textAlign = "right";
        }
        textY = endY - totalHeight / 2;
      }

      // Clamp horizontally to stay inside canvas bounds
      if (ctx.textAlign === "left") {
        if (textX + maxLineWidth > chart.width - 4) {
          textX = Math.max(endX + 2, chart.width - 4 - maxLineWidth);
        }
      } else if (ctx.textAlign === "right") {
        if (textX - maxLineWidth < 4) {
          textX = Math.min(endX - 2, 4 + maxLineWidth);
        }
      } else if (textX - maxLineWidth / 2 < 4) {
        textX = 4 + maxLineWidth / 2;
      } else if (textX + maxLineWidth / 2 > chart.width - 4) {
        textX = chart.width - 4 - maxLineWidth / 2;
      }

      // Clamp vertically to stay inside canvas bounds
      if (textY < 12) {
        textY = 12;
      } else if (textY + totalHeight > chart.height - 4) {
        textY = Math.max(12, chart.height - 4 - totalHeight);
      }

      ctx.textBaseline = "top";
      lines.forEach((lineText, lineIdx) => {
        ctx.fillText(lineText, textX, textY + lineIdx * lineHeight);
      });

      ctx.restore();
    });
  }
};

function NewDashboard() {
  const [metrics, setMetrics] = useState({
    total: null,
    open: null,
    closed: null,
    openMale: null,
    closedMale: null,
    openFemale: null,
    closedFemale: null,
    openTrans: null,
    closedTrans: null
  });

  const [sourceChartData, setSourceChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [genderChartData, setGenderChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [timelineChartData, setTimelineChartData] = useState({
    labels: [],
    total: [],
    open: [],
    closed: []
  });

  const [natureChartData, setNatureChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [servicesChartData, setServicesChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [incidentsChartData, setIncidentsChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [vulnerabilitiesChartData, setVulnerabilitiesChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [diagnosedDisabilityChartData, setDiagnosedDisabilityChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [undiagnosedDisabilityChartData, setUndiagnosedDisabilityChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [districtChartData, setDistrictChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [tehsilChartData, setTehsilChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [incidentLocationChartData, setIncidentLocationChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [careArrangementChartData, setCareArrangementChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [caseWorkerChartData, setCaseWorkerChartData] = useState({
    labels: [],
    total: [],
    open: [],
    closed: []
  });

  const [maritalStatusChartData, setMaritalStatusChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [nationalityChartData, setNationalityChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [educationChartData, setEducationChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [languageChartData, setLanguageChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [religionChartData, setReligionChartData] = useState({
    labels: [],
    data: [],
    colors: []
  });

  const [ageGroupChartData, setAgeGroupChartData] = useState({
    labels: [],
    open: [],
    closed: []
  });

  const [workflowChartData, setWorkflowChartData] = useState({
    labels: [],
    data: []
  });

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const sourceCanvasRef = useRef(null);
  const genderCanvasRef = useRef(null);
  const timelineCanvasRef = useRef(null);
  const natureCanvasRef = useRef(null);
  const servicesCanvasRef = useRef(null);
  const incidentsCanvasRef = useRef(null);
  const vulnerabilitiesCanvasRef = useRef(null);
  const diagnosedDisabilityCanvasRef = useRef(null);
  const undiagnosedDisabilityCanvasRef = useRef(null);
  const districtCanvasRef = useRef(null);
  const tehsilCanvasRef = useRef(null);
  const incidentLocationCanvasRef = useRef(null);
  const careArrangementCanvasRef = useRef(null);
  const caseWorkerCanvasRef = useRef(null);
  const maritalStatusCanvasRef = useRef(null);
  const nationalityCanvasRef = useRef(null);
  const educationCanvasRef = useRef(null);
  const languageCanvasRef = useRef(null);
  const religionCanvasRef = useRef(null);
  const ageGroupCanvasRef = useRef(null);
  const workflowCanvasRef = useRef(null);

  const sourceChartInstance = useRef(null);
  const genderChartInstance = useRef(null);
  const timelineChartInstance = useRef(null);
  const natureChartInstance = useRef(null);
  const servicesChartInstance = useRef(null);
  const incidentsChartInstance = useRef(null);
  const vulnerabilitiesChartInstance = useRef(null);
  const diagnosedDisabilityChartInstance = useRef(null);
  const undiagnosedDisabilityChartInstance = useRef(null);
  const districtChartInstance = useRef(null);
  const tehsilChartInstance = useRef(null);
  const incidentLocationChartInstance = useRef(null);
  const careArrangementChartInstance = useRef(null);
  const caseWorkerChartInstance = useRef(null);
  const maritalStatusChartInstance = useRef(null);
  const nationalityChartInstance = useRef(null);
  const educationChartInstance = useRef(null);
  const languageChartInstance = useRef(null);
  const religionChartInstance = useRef(null);
  const ageGroupChartInstance = useRef(null);
  const workflowChartInstance = useRef(null);

  const fetchCasesData = useCallback(async () => {
    setLoading(true);
    setError(null);

    const headers = {
      Accept: "application/json",
      "Content-Type": "application/json"
    };

    const fetchOptions = {
      method: "GET",
      headers,
      credentials: "include"
    };

    try {
      const [
        casesRes,
        newDashboardRes,
        locationsRes,
        usersRes,
        genderLookup,
        sourceLookup,
        incidentsLookup,
        vulnerabilitiesLookup,
        diagnosedLookup,
        natureLookup,
        undiagnosedLookup,
        servicesLookup,
        careArrangementLookup,
        incidentLocationLookup,
        maritalStatusLookup,
        nationalityLookup,
        languageLookup,
        religionLookup
      ] = await Promise.all([
        fetch("/api/v2/cases?record_state=true&per=500", fetchOptions),
        fetch("/api/v2/new_dashboards?record_state=true", fetchOptions).catch(() => null),
        fetch("/api/v2/locations?per=500", fetchOptions).catch(() => null),
        fetch("/api/v2/users?per=500", fetchOptions).catch(() => null),
        fetchLookupMap(31, fetchOptions),
        fetchLookupMap(329, fetchOptions),
        fetchLookupMap(20, fetchOptions),
        fetchLookupMap(372, fetchOptions),
        fetchLookupMap(64, fetchOptions),
        fetchLookupMap(13, fetchOptions),
        fetchLookupMap(341, fetchOptions),
        fetchLookupMap(18, fetchOptions),
        fetchLookupMap(26, fetchOptions),
        fetchLookupMap(41, fetchOptions),
        fetchLookupMap(37, fetchOptions),
        fetchLookupMap(2, fetchOptions),
        fetchLookupMap(5, fetchOptions),
        fetchLookupMap(6, fetchOptions)
      ]);

      if (!casesRes.ok && (!newDashboardRes || !newDashboardRes.ok)) {
        throw new Error("Failed to fetch cases data");
      }

      const locationMap = {};

      if (locationsRes && locationsRes.ok) {
        const locJson = await locationsRes.json();
        const locList = locJson?.data || [];

        locList.forEach(loc => {
          if (loc && loc.code) {
            const nameEn = loc.name?.en || (typeof loc.name === "string" ? loc.name : "");

            if (nameEn) {
              locationMap[loc.code] = nameEn;
            }
          }
        });
      }

      const userMap = {};

      if (usersRes && usersRes.ok) {
        const usersJson = await usersRes.json();
        const usersList = usersJson?.data || [];

        usersList.forEach(u => {
          if (u && u.user_name) {
            userMap[u.user_name] = u.full_name || u.user_name;
          }
        });
      }

      let totalCount = 0;
      let openCasesCount = 0;
      let closedCasesCount = 0;
      let openMale = 0;
      let closedMale = 0;
      let openFemale = 0;
      let closedFemale = 0;
      let openTrans = 0;
      let closedTrans = 0;

      const sourceMap = {};
      const genderCountsMap = {};
      const natureRiskMap = {};
      const monthMap = {};
      const servicesMap = {};
      const incidentsMap = {};
      const vulnerabilitiesMap = {};
      const diagnosedDisabilityMap = {};
      const undiagnosedDisabilityMap = {};
      const districtMap = {};
      const tehsilMap = {};
      const incidentLocationMap = {};
      const careArrangementMap = {};
      const caseWorkerMap = {};
      const maritalStatusMap = {};
      const nationalityMap = {};
      const educationMap = {};
      const languageMap = {};
      const religionMap = {};
      const ageGroupMap = {};

      AGE_GROUP_DEFINITIONS.forEach(({ key }) => {
        ageGroupMap[key] = { open: 0, closed: 0 };
      });

      const workflowMap = {};

      WORKFLOW_DEFINITIONS.forEach(({ key }) => {
        workflowMap[key] = 0;
      });

      if (casesRes.ok) {
        const casesJson = await casesRes.json();
        const casesList = casesJson?.data || [];

        totalCount = casesJson?.metadata?.total ?? casesList.length;

        casesList.forEach(c => {
          const status = (c.status || "open").toLowerCase();
          const isOpen = status === "open";
          const isClosed = status === "closed";
          const sex = (c.sex || "").toLowerCase();
          const sourceVal = c.source_of_information_4442e8c;
          const rawDate = c.registration_date;
          const ym = String(rawDate || "").substring(0, 7);

          if (isOpen) {
            openCasesCount += 1;
          } else if (isClosed) {
            closedCasesCount += 1;
          }

          if (sourceVal) {
            if (!sourceMap[sourceVal]) {
              sourceMap[sourceVal] = { open: 0, closed: 0 };
            }
            if (isOpen) {
              sourceMap[sourceVal].open += 1;
            } else if (isClosed) {
              sourceMap[sourceVal].closed += 1;
            }
          }

          if (sex) {
            genderCountsMap[sex] = (genderCountsMap[sex] || 0) + 1;
          }

          if (sex === "male") {
            if (isOpen) openMale += 1;
            if (isClosed) closedMale += 1;
          } else if (sex === "female") {
            if (isOpen) openFemale += 1;
            if (isClosed) closedFemale += 1;
          } else if (sex.includes("transgender")) {
            if (isOpen) openTrans += 1;
            if (isClosed) closedTrans += 1;
          }

          const risk = String(c.risk_level || "")
            .toLowerCase()
            .trim();

          if (risk) {
            natureRiskMap[risk] = (natureRiskMap[risk] || 0) + 1;
          }

          const servicesSection = Array.isArray(c.services_section) ? c.services_section : [];
          const distinctServices = new Set();

          servicesSection.forEach(s => {
            if (s && s.service_type) {
              distinctServices.add(s.service_type);
            }
          });

          distinctServices.forEach(st => {
            if (!servicesMap[st]) {
              servicesMap[st] = {
                open: 0,
                closed: 0
              };
            }
            if (isOpen) {
              servicesMap[st].open += 1;
            } else if (isClosed) {
              servicesMap[st].closed += 1;
            }
          });

          const protectionConcerns = Array.isArray(c.protection_concerns) ? c.protection_concerns : [];
          const distinctConcerns = new Set();

          protectionConcerns.forEach(pc => {
            if (pc) {
              distinctConcerns.add(pc);
            }
          });

          distinctConcerns.forEach(pc => {
            if (!incidentsMap[pc]) {
              incidentsMap[pc] = {
                open: 0,
                closed: 0
              };
            }
            if (isOpen) {
              incidentsMap[pc].open += 1;
            } else if (isClosed) {
              incidentsMap[pc].closed += 1;
            }
          });

          const vulnerabilities = Array.isArray(c.vulnerabilities_aba2a7a) ? c.vulnerabilities_aba2a7a : [];
          const distinctVulnerabilities = new Set();

          vulnerabilities.forEach(v => {
            if (v) {
              distinctVulnerabilities.add(v);
            }
          });

          distinctVulnerabilities.forEach(v => {
            if (!vulnerabilitiesMap[v]) {
              vulnerabilitiesMap[v] = {
                open: 0,
                closed: 0
              };
            }
            if (isOpen) {
              vulnerabilitiesMap[v].open += 1;
            } else if (isClosed) {
              vulnerabilitiesMap[v].closed += 1;
            }
          });

          const diagnosedList = toArray(c.does_the_child_have_any_of_the_following_disabilities__2a1788b);
          const distinctDiagnosed = new Set(diagnosedList.filter(Boolean));

          distinctDiagnosed.forEach(d => {
            diagnosedDisabilityMap[d] = (diagnosedDisabilityMap[d] || 0) + 1;
          });

          const undiagnosedList = toArray(c.undiagnosed_disability_b164b9c);
          const distinctUndiagnosed = new Set(undiagnosedList.filter(Boolean));

          distinctUndiagnosed.forEach(u => {
            undiagnosedDisabilityMap[u] = (undiagnosedDisabilityMap[u] || 0) + 1;
          });

          const locCode = c.location_current;
          const locName = locCode ? locationMap[locCode] : null;

          if (locName) {
            const parts = locName.split(":");
            const district = parts[2] ? parts[2].trim() : null;
            const tehsil = parts[3] ? parts[3].trim() : null;

            if (district) {
              if (!districtMap[district]) {
                districtMap[district] = { open: 0, closed: 0 };
              }
              if (isOpen) {
                districtMap[district].open += 1;
              } else if (isClosed) {
                districtMap[district].closed += 1;
              }
            }

            if (tehsil) {
              if (!tehsilMap[tehsil]) {
                tehsilMap[tehsil] = { open: 0, closed: 0 };
              }
              if (isOpen) {
                tehsilMap[tehsil].open += 1;
              } else if (isClosed) {
                tehsilMap[tehsil].closed += 1;
              }
            }
          }

          const incidentLoc = c.location_of_the_incident_1f10ef1;

          if (incidentLoc) {
            incidentLocationMap[incidentLoc] = (incidentLocationMap[incidentLoc] || 0) + 1;
          }

          const careArrangement = c.current_care_arrangements_type;

          if (careArrangement) {
            careArrangementMap[careArrangement] = (careArrangementMap[careArrangement] || 0) + 1;
          }

          const ownedBy = c.owned_by;

          if (ownedBy) {
            if (!caseWorkerMap[ownedBy]) {
              caseWorkerMap[ownedBy] = { total: 0, open: 0, closed: 0 };
            }
            caseWorkerMap[ownedBy].total += 1;
            if (isOpen) {
              caseWorkerMap[ownedBy].open += 1;
            } else if (isClosed) {
              caseWorkerMap[ownedBy].closed += 1;
            }
          }

          const maritalVal = c.maritial_status || c.marital_status;

          if (maritalVal) {
            maritalStatusMap[maritalVal] = (maritalStatusMap[maritalVal] || 0) + 1;
          }

          const nationalityList = toArray(c.nationality);
          const distinctNationalities = new Set(nationalityList.filter(Boolean));

          distinctNationalities.forEach(nat => {
            nationalityMap[nat] = (nationalityMap[nat] || 0) + 1;
          });

          const educationVal = c.is_the_child_enrolled_in_formal_education__a512ab5;

          if (educationVal !== null && educationVal !== undefined && educationVal !== "") {
            const eduKey = String(educationVal).toLowerCase().trim();

            educationMap[eduKey] = (educationMap[eduKey] || 0) + 1;
          }

          const languageList = toArray(c.language);
          const distinctLanguages = new Set(languageList.filter(Boolean));

          distinctLanguages.forEach(lang => {
            languageMap[lang] = (languageMap[lang] || 0) + 1;
          });

          const religionList = toArray(c.religion);
          const distinctReligions = new Set(religionList.filter(Boolean));

          distinctReligions.forEach(rel => {
            religionMap[rel] = (religionMap[rel] || 0) + 1;
          });

          const ageGroup = getAgeGroup(c.age);

          if (isOpen) {
            ageGroupMap[ageGroup].open += 1;
          } else if (isClosed) {
            ageGroupMap[ageGroup].closed += 1;
          }

          if (isOpen && c.workflow) {
            const wf = String(c.workflow).toLowerCase();

            if (workflowMap[wf] !== undefined) {
              workflowMap[wf] += 1;
            }
          }

          if (ym && ym.length === 7) {
            if (!monthMap[ym]) {
              monthMap[ym] = { total: 0, open: 0, closed: 0 };
            }
            monthMap[ym].total += 1;
            if (isOpen) {
              monthMap[ym].open += 1;
            } else if (isClosed) {
              monthMap[ym].closed += 1;
            }
          }
        });
      }

      if (newDashboardRes && newDashboardRes.ok) {
        const dashJson = await newDashboardRes.json();
        const m = dashJson?.metadata;

        if (m) {
          if (m.total !== undefined) totalCount = m.total;
          if (m.open !== undefined) openCasesCount = m.open;
          if (m.closed !== undefined) closedCasesCount = m.closed;
          if (m.open_male !== undefined) openMale = m.open_male;
          if (m.closed_male !== undefined) closedMale = m.closed_male;
          if (m.open_female !== undefined) openFemale = m.open_female;
          if (m.closed_female !== undefined) closedFemale = m.closed_female;
          if (m.open_transgender !== undefined) openTrans = m.open_transgender;
          if (m.closed_transgender !== undefined) closedTrans = m.closed_transgender;
        }

        const serverSources = dashJson?.charts?.source_of_information;

        if (serverSources) {
          Object.keys(serverSources).forEach(k => {
            if (!sourceMap[k]) {
              sourceMap[k] = { open: 0, closed: 0 };
            }
            sourceMap[k].open = serverSources[k].open || 0;
            sourceMap[k].closed = serverSources[k].closed || 0;
          });
        }

        const serverGender = dashJson?.charts?.cases_per_gender;

        if (serverGender) {
          Object.keys(serverGender).forEach(k => {
            if (serverGender[k] && serverGender[k].count !== undefined) {
              genderCountsMap[k] = serverGender[k].count;
            }
          });
        }

        const serverMonths = dashJson?.charts?.cases_per_month_year;

        if (serverMonths) {
          Object.keys(serverMonths).forEach(mKey => {
            if (!monthMap[mKey]) {
              monthMap[mKey] = { total: 0, open: 0, closed: 0 };
            }
            monthMap[mKey].total = serverMonths[mKey].total;
            monthMap[mKey].open = serverMonths[mKey].open;
            monthMap[mKey].closed = serverMonths[mKey].closed;
          });
        }

        const serverNature = dashJson?.charts?.nature_of_cases;

        if (serverNature) {
          Object.keys(serverNature).forEach(k => {
            if (serverNature[k] && serverNature[k].count !== undefined) {
              natureRiskMap[k] = serverNature[k].count;
            }
          });
        }

        const serverServices = dashJson?.charts?.cases_per_services_provided;

        if (serverServices && Object.keys(servicesMap).length === 0) {
          Object.keys(serverServices).forEach(st => {
            servicesMap[st] = {
              open: serverServices[st].open || 0,
              closed: serverServices[st].closed || 0
            };
          });
        }

        const serverIncidents = dashJson?.charts?.cases_per_incidents;

        if (serverIncidents && Object.keys(incidentsMap).length === 0) {
          Object.keys(serverIncidents).forEach(pc => {
            incidentsMap[pc] = {
              open: serverIncidents[pc].open || 0,
              closed: serverIncidents[pc].closed || 0
            };
          });
        }

        const serverVulnerabilities = dashJson?.charts?.cases_per_vulnerabilities;

        if (serverVulnerabilities && Object.keys(vulnerabilitiesMap).length === 0) {
          Object.keys(serverVulnerabilities).forEach(v => {
            vulnerabilitiesMap[v] = {
              open: serverVulnerabilities[v].open || 0,
              closed: serverVulnerabilities[v].closed || 0
            };
          });
        }

        const serverDiagnosed = dashJson?.charts?.cases_per_diagnosed_disability;

        if (serverDiagnosed && Object.keys(diagnosedDisabilityMap).length === 0) {
          Object.keys(serverDiagnosed).forEach(d => {
            diagnosedDisabilityMap[d] = serverDiagnosed[d];
          });
        }

        const serverUndiagnosed = dashJson?.charts?.cases_per_undiagnosed_disability;

        if (serverUndiagnosed && Object.keys(undiagnosedDisabilityMap).length === 0) {
          Object.keys(serverUndiagnosed).forEach(u => {
            undiagnosedDisabilityMap[u] = serverUndiagnosed[u];
          });
        }

        const serverDistrict = dashJson?.charts?.cases_per_district;

        if (serverDistrict && Object.keys(districtMap).length === 0) {
          Object.keys(serverDistrict).forEach(k => {
            districtMap[k] = {
              open: serverDistrict[k].open || 0,
              closed: serverDistrict[k].closed || 0
            };
          });
        }

        const serverTehsil = dashJson?.charts?.cases_per_tehsil;

        if (serverTehsil && Object.keys(tehsilMap).length === 0) {
          Object.keys(serverTehsil).forEach(k => {
            tehsilMap[k] = {
              open: serverTehsil[k].open || 0,
              closed: serverTehsil[k].closed || 0
            };
          });
        }

        const serverIncidentLocation = dashJson?.charts?.cases_per_incident_location;

        if (serverIncidentLocation && Object.keys(incidentLocationMap).length === 0) {
          Object.keys(serverIncidentLocation).forEach(k => {
            incidentLocationMap[k] = serverIncidentLocation[k];
          });
        }

        const serverCareArrangement = dashJson?.charts?.cases_per_care_arrangement;

        if (serverCareArrangement && Object.keys(careArrangementMap).length === 0) {
          Object.keys(serverCareArrangement).forEach(k => {
            careArrangementMap[k] = serverCareArrangement[k];
          });
        }

        const serverCaseWorkers = dashJson?.charts?.cases_per_case_worker;

        if (serverCaseWorkers && Object.keys(caseWorkerMap).length === 0) {
          Object.keys(serverCaseWorkers).forEach(k => {
            const entry = serverCaseWorkers[k];

            if (entry) {
              caseWorkerMap[k] = {
                label: entry.label,
                total: entry.total || 0,
                open: entry.open || 0,
                closed: entry.closed || 0
              };
            }
          });
        }

        const serverMarital = dashJson?.charts?.cases_per_marital_status;

        if (serverMarital && Object.keys(maritalStatusMap).length === 0) {
          Object.keys(serverMarital).forEach(k => {
            maritalStatusMap[k] = serverMarital[k];
          });
        }

        const serverNationality = dashJson?.charts?.cases_per_nationality;

        if (serverNationality && Object.keys(nationalityMap).length === 0) {
          Object.keys(serverNationality).forEach(k => {
            nationalityMap[k] = serverNationality[k];
          });
        }

        const serverEducation = dashJson?.charts?.cases_per_child_getting_education;

        if (serverEducation && Object.keys(educationMap).length === 0) {
          Object.keys(serverEducation).forEach(k => {
            educationMap[k] = serverEducation[k];
          });
        }

        const serverLanguage = dashJson?.charts?.cases_per_language;

        if (serverLanguage && Object.keys(languageMap).length === 0) {
          Object.keys(serverLanguage).forEach(k => {
            languageMap[k] = serverLanguage[k];
          });
        }

        const serverReligion = dashJson?.charts?.cases_per_religion;

        if (serverReligion && Object.keys(religionMap).length === 0) {
          Object.keys(serverReligion).forEach(k => {
            religionMap[k] = serverReligion[k];
          });
        }

        const serverAgeGroups = dashJson?.charts?.cases_per_age_groups;

        if (serverAgeGroups && Object.values(ageGroupMap).every(v => v.open === 0 && v.closed === 0)) {
          Object.keys(serverAgeGroups).forEach(k => {
            if (!ageGroupMap[k]) {
              ageGroupMap[k] = { open: 0, closed: 0 };
            }
            ageGroupMap[k].open = serverAgeGroups[k].open || 0;
            ageGroupMap[k].closed = serverAgeGroups[k].closed || 0;
          });
        }

        const serverWorkflow = dashJson?.charts?.cases_per_workflow;

        if (serverWorkflow && Object.values(workflowMap).every(v => v === 0)) {
          Object.keys(serverWorkflow).forEach(k => {
            if (workflowMap[k] !== undefined) {
              workflowMap[k] = serverWorkflow[k] || 0;
            }
          });
        }
      }

      setMetrics({
        total: totalCount,
        open: openCasesCount,
        closed: closedCasesCount,
        openMale,
        closedMale,
        openFemale,
        closedFemale,
        openTrans,
        closedTrans
      });

      // Sort sources in DESCENDING ORDER by total cases (open + closed) for the row chart
      const sortedSources = Object.keys(sourceMap)
        .map(key => {
          const openCount = sourceMap[key]?.open || 0;
          const closedCount = sourceMap[key]?.closed || 0;

          return {
            key,
            label: sourceLookup[key] || formatFallbackLabel(key),
            open: openCount,
            closed: closedCount,
            total: openCount + closedCount
          };
        })
        .filter(s => s.total > 0)
        .sort((a, b) => b.total - a.total);

      setSourceChartData({
        labels: sortedSources.map(s => s.label),
        open: sortedSources.map(s => s.open),
        closed: sortedSources.map(s => s.closed)
      });

      // Prepare Cases per Gender pie chart data (descending order)
      const sortedGenders = Object.keys(genderCountsMap)
        .map(key => ({
          key,
          label: genderLookup[key] || formatFallbackLabel(key),
          count: genderCountsMap[key]
        }))
        .filter(g => g.count > 0)
        .sort((a, b) => b.count - a.count);

      setGenderChartData({
        labels: sortedGenders.map(g => g.label),
        data: sortedGenders.map(g => g.count),
        colors: sortedGenders.map((_, idx) => GENDER_COLORS[idx % GENDER_COLORS.length])
      });

      // Prepare Cases per Month/Year chronological trend data
      const sortedMonths = Object.keys(monthMap).sort();

      setTimelineChartData({
        labels: sortedMonths.map(formatMonthYear),
        total: sortedMonths.map(m => monthMap[m].total),
        open: sortedMonths.map(m => monthMap[m].open),
        closed: sortedMonths.map(m => monthMap[m].closed)
      });

      // Prepare Nature of Cases pie chart data (descending order)
      const sortedNature = Object.keys(natureRiskMap)
        .map(key => ({
          key,
          label: natureLookup[key] || formatFallbackLabel(key),
          count: natureRiskMap[key]
        }))
        .filter(n => n.count > 0)
        .sort((a, b) => b.count - a.count);

      setNatureChartData({
        labels: sortedNature.map(n => n.label),
        data: sortedNature.map(n => n.count),
        colors: sortedNature.map((_, idx) => NATURE_COLORS[idx % NATURE_COLORS.length])
      });

      // Sort services in DESCENDING ORDER by total cases (open + closed) for the row chart
      const sortedServices = Object.keys(servicesMap)
        .map(key => ({
          key,
          label: servicesLookup[key] || formatFallbackLabel(key),
          open: servicesMap[key].open,
          closed: servicesMap[key].closed,
          total: servicesMap[key].open + servicesMap[key].closed
        }))
        .filter(s => s.total > 0)
        .sort((a, b) => b.total - a.total);

      setServicesChartData({
        labels: sortedServices.map(s => s.label),
        open: sortedServices.map(s => s.open),
        closed: sortedServices.map(s => s.closed)
      });

      // Sort incidents in DESCENDING ORDER by total cases (open + closed) for the bar chart
      const sortedIncidents = Object.keys(incidentsMap)
        .map(key => ({
          key,
          label: incidentsLookup[key] || formatFallbackLabel(key),
          open: incidentsMap[key].open,
          closed: incidentsMap[key].closed,
          total: incidentsMap[key].open + incidentsMap[key].closed
        }))
        .filter(i => i.total > 0)
        .sort((a, b) => b.total - a.total);

      setIncidentsChartData({
        labels: sortedIncidents.map(i => i.label),
        open: sortedIncidents.map(i => i.open),
        closed: sortedIncidents.map(i => i.closed)
      });

      // Sort vulnerabilities in DESCENDING ORDER by total cases (open + closed) for the bar chart
      const sortedVulnerabilities = Object.keys(vulnerabilitiesMap)
        .map(key => ({
          key,
          label: vulnerabilitiesLookup[key] || formatFallbackLabel(key),
          open: vulnerabilitiesMap[key].open,
          closed: vulnerabilitiesMap[key].closed,
          total: vulnerabilitiesMap[key].open + vulnerabilitiesMap[key].closed
        }))
        .filter(v => v.total > 0)
        .sort((a, b) => b.total - a.total);

      setVulnerabilitiesChartData({
        labels: sortedVulnerabilities.map(v => v.label),
        open: sortedVulnerabilities.map(v => v.open),
        closed: sortedVulnerabilities.map(v => v.closed)
      });

      // Prepare Cases per Diagnosed Disability pie chart data (descending order)
      const sortedDiagnosed = Object.keys(diagnosedDisabilityMap)
        .map(key => ({
          key,
          label: diagnosedLookup[key] || formatFallbackLabel(key),
          count: diagnosedDisabilityMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setDiagnosedDisabilityChartData({
        labels: sortedDiagnosed.map(d => d.label),
        data: sortedDiagnosed.map(d => d.count),
        colors: sortedDiagnosed.map((_, idx) => DIAGNOSED_COLORS[idx % DIAGNOSED_COLORS.length])
      });

      // Prepare Cases per Undiagnosed Disability pie chart data (descending order)
      const sortedUndiagnosed = Object.keys(undiagnosedDisabilityMap)
        .map(key => ({
          key,
          label: undiagnosedLookup[key] || formatFallbackLabel(key),
          count: undiagnosedDisabilityMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setUndiagnosedDisabilityChartData({
        labels: sortedUndiagnosed.map(u => u.label),
        data: sortedUndiagnosed.map(u => u.count),
        colors: sortedUndiagnosed.map((_, idx) => UNDIAGNOSED_COLORS[idx % UNDIAGNOSED_COLORS.length])
      });

      // Sort districts in DESCENDING ORDER by total cases (open + closed) for the bar chart
      const sortedDistricts = Object.keys(districtMap)
        .map(key => ({
          label: key,
          open: districtMap[key].open,
          closed: districtMap[key].closed,
          total: districtMap[key].open + districtMap[key].closed
        }))
        .filter(d => d.total > 0)
        .sort((a, b) => b.total - a.total);

      setDistrictChartData({
        labels: sortedDistricts.map(d => d.label),
        open: sortedDistricts.map(d => d.open),
        closed: sortedDistricts.map(d => d.closed)
      });

      // Sort tehsils in DESCENDING ORDER by total cases (open + closed) for the bar chart
      const sortedTehsils = Object.keys(tehsilMap)
        .map(key => ({
          label: key,
          open: tehsilMap[key].open,
          closed: tehsilMap[key].closed,
          total: tehsilMap[key].open + tehsilMap[key].closed
        }))
        .filter(t => t.total > 0)
        .sort((a, b) => b.total - a.total);

      setTehsilChartData({
        labels: sortedTehsils.map(t => t.label),
        open: sortedTehsils.map(t => t.open),
        closed: sortedTehsils.map(t => t.closed)
      });

      // Prepare Location of Incident pie chart data (descending order)
      const sortedIncidentLocations = Object.keys(incidentLocationMap)
        .map(key => ({
          key,
          label: incidentLocationLookup[key] || formatFallbackLabel(key),
          count: incidentLocationMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setIncidentLocationChartData({
        labels: sortedIncidentLocations.map(item => item.label),
        data: sortedIncidentLocations.map(item => item.count),
        colors: sortedIncidentLocations.map((_, idx) => INCIDENT_LOCATION_COLORS[idx % INCIDENT_LOCATION_COLORS.length])
      });

      // Prepare Cases per Care Arrangement pie chart data (descending order)
      const sortedCareArrangements = Object.keys(careArrangementMap)
        .map(key => ({
          key,
          label: careArrangementLookup[key] || formatFallbackLabel(key),
          count: careArrangementMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setCareArrangementChartData({
        labels: sortedCareArrangements.map(item => item.label),
        data: sortedCareArrangements.map(item => item.count),
        colors: sortedCareArrangements.map((_, idx) => CARE_ARRANGEMENT_COLORS[idx % CARE_ARRANGEMENT_COLORS.length])
      });

      // Prepare Cases per Caseworker line chart data (descending order)
      const sortedCaseWorkers = Object.keys(caseWorkerMap)
        .map(userName => ({
          userName,
          label: userMap[userName] || caseWorkerMap[userName].label || formatFallbackLabel(userName),
          total: caseWorkerMap[userName].total,
          open: caseWorkerMap[userName].open,
          closed: caseWorkerMap[userName].closed
        }))
        .filter(item => item.total > 0)
        .sort((a, b) => b.total - a.total);

      setCaseWorkerChartData({
        labels: sortedCaseWorkers.map(w => w.label),
        total: sortedCaseWorkers.map(w => w.total),
        open: sortedCaseWorkers.map(w => w.open),
        closed: sortedCaseWorkers.map(w => w.closed)
      });

      // Prepare Cases per Marital Status pie chart data (descending order)
      const sortedMarital = Object.keys(maritalStatusMap)
        .map(key => ({
          key,
          label: maritalStatusLookup[key] || formatFallbackLabel(key),
          count: maritalStatusMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setMaritalStatusChartData({
        labels: sortedMarital.map(item => item.label),
        data: sortedMarital.map(item => item.count),
        colors: sortedMarital.map((_, idx) => MARITAL_STATUS_COLORS[idx % MARITAL_STATUS_COLORS.length])
      });

      // Prepare Cases per Nationality pie chart data (descending order)
      const sortedNationality = Object.keys(nationalityMap)
        .map(key => ({
          key,
          label: nationalityLookup[key] || formatFallbackLabel(key),
          count: nationalityMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setNationalityChartData({
        labels: sortedNationality.map(item => item.label),
        data: sortedNationality.map(item => item.count),
        colors: sortedNationality.map((_, idx) => NATIONALITY_COLORS[idx % NATIONALITY_COLORS.length])
      });

      // Prepare Cases per Child getting Education pie chart data (descending order)
      const sortedEducation = Object.keys(educationMap)
        .map(key => ({
          key,
          label: formatEducationLabel(key),
          count: educationMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setEducationChartData({
        labels: sortedEducation.map(item => item.label),
        data: sortedEducation.map(item => item.count),
        colors: sortedEducation.map((_, idx) => EDUCATION_COLORS[idx % EDUCATION_COLORS.length])
      });

      // Prepare Cases per Language pie chart data (descending order)
      const sortedLanguage = Object.keys(languageMap)
        .map(key => ({
          key,
          label: languageLookup[key] || formatFallbackLabel(key),
          count: languageMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setLanguageChartData({
        labels: sortedLanguage.map(item => item.label),
        data: sortedLanguage.map(item => item.count),
        colors: sortedLanguage.map((_, idx) => LANGUAGE_COLORS[idx % LANGUAGE_COLORS.length])
      });

      // Prepare Cases per Religion pie chart data (descending order)
      const sortedReligion = Object.keys(religionMap)
        .map(key => ({
          key,
          label: religionLookup[key] || formatFallbackLabel(key),
          count: religionMap[key]
        }))
        .filter(item => item.count > 0)
        .sort((a, b) => b.count - a.count);

      setReligionChartData({
        labels: sortedReligion.map(item => item.label),
        data: sortedReligion.map(item => item.count),
        colors: sortedReligion.map((_, idx) => RELIGION_COLORS[idx % RELIGION_COLORS.length])
      });

      // Prepare Cases per Age-Groups row chart data (in defined order: 0-5, 6-9, 10-13, 14-18, 18+, Unknown)
      const orderedAgeGroups = AGE_GROUP_DEFINITIONS.map(({ key, label }) => {
        const openCount = ageGroupMap[key]?.open || 0;
        const closedCount = ageGroupMap[key]?.closed || 0;

        return {
          key,
          label,
          open: openCount,
          closed: closedCount
        };
      });

      setAgeGroupChartData({
        labels: orderedAgeGroups.map(item => item.label),
        open: orderedAgeGroups.map(item => item.open),
        closed: orderedAgeGroups.map(item => item.closed)
      });

      // Prepare Cases per Workflow row chart data (in defined order, open cases only)
      const orderedWorkflows = WORKFLOW_DEFINITIONS.map(({ key, label }) => ({
        key,
        label,
        count: workflowMap[key] || 0
      }));

      setWorkflowChartData({
        labels: orderedWorkflows.map(item => item.label),
        data: orderedWorkflows.map(item => item.count)
      });
    } catch (err) {
      setError(err?.message || "Failed to load dashboard data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCasesData();
  }, [fetchCasesData]);

  // Render "Cases per Source of information" row chart in descending order
  useEffect(() => {
    if (!sourceCanvasRef.current || !sourceChartData.labels.length) {
      return undefined;
    }

    if (sourceChartInstance.current) {
      sourceChartInstance.current.destroy();
    }

    const ctx = sourceCanvasRef.current.getContext("2d");

    sourceChartInstance.current = new Chart(ctx, {
      type: "horizontalBar",
      data: {
        labels: sourceChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: sourceChartData.open,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: sourceChartData.closed,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: { display: false },
              ticks: {
                fontColor: "#1e293b",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false,
          callbacks: {
            footer: tooltipItems => {
              const total = tooltipItems.reduce((acc, item) => acc + Number(item.xLabel || 0), 0);

              return `Total: ${total}`;
            }
          }
        }
      }
    });

    return () => {
      if (sourceChartInstance.current) {
        sourceChartInstance.current.destroy();
      }
    };
  }, [sourceChartData]);

  // Render "Cases per Gender" pie chart with inline labels
  useEffect(() => {
    if (!genderCanvasRef.current || !genderChartData.data.length) {
      return undefined;
    }

    if (genderChartInstance.current) {
      genderChartInstance.current.destroy();
    }

    const ctx = genderCanvasRef.current.getContext("2d");

    genderChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: genderChartData.labels,
        datasets: [
          {
            data: genderChartData.data,
            backgroundColor: genderChartData.colors,
            hoverBackgroundColor: ["#00a5d2", "#d61fb0", "#7c3aed"],
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, data) => {
              const label = data.labels[tooltipItem.index] || "";
              const val = data.datasets[0].data[tooltipItem.index];
              const total = data.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return `${label}: ${val} cases (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (genderChartInstance.current) {
        genderChartInstance.current.destroy();
      }
    };
  }, [genderChartData]);

  // Render "Cases per Month/Year" line chart
  useEffect(() => {
    if (!timelineCanvasRef.current || !timelineChartData.labels.length) {
      return undefined;
    }

    if (timelineChartInstance.current) {
      timelineChartInstance.current.destroy();
    }

    const ctx = timelineCanvasRef.current.getContext("2d");

    timelineChartInstance.current = new Chart(ctx, {
      type: "line",
      data: {
        labels: timelineChartData.labels,
        datasets: [
          {
            label: "Total Cases",
            borderColor: "#0284c7",
            backgroundColor: "rgba(2, 132, 199, 0.08)",
            pointBackgroundColor: "#0284c7",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#0284c7",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: true,
            data: timelineChartData.total
          },
          {
            label: "Open Cases",
            borderColor: "#00c0f0",
            backgroundColor: "transparent",
            pointBackgroundColor: "#00c0f0",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#00c0f0",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: false,
            data: timelineChartData.open
          },
          {
            label: "Closed Cases",
            borderColor: "#f02fc2",
            backgroundColor: "transparent",
            pointBackgroundColor: "#f02fc2",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#f02fc2",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: false,
            data: timelineChartData.closed
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#64748b",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (timelineChartInstance.current) {
        timelineChartInstance.current.destroy();
      }
    };
  }, [timelineChartData]);

  // Render "Nature of Cases" pie chart with inline labels
  useEffect(() => {
    if (!natureCanvasRef.current || !natureChartData.data.length) {
      return undefined;
    }

    if (natureChartInstance.current) {
      natureChartInstance.current.destroy();
    }

    const ctx = natureCanvasRef.current.getContext("2d");

    natureChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: natureChartData.labels,
        datasets: [
          {
            data: natureChartData.data,
            backgroundColor: natureChartData.colors,
            hoverBackgroundColor: ["#dc2626", "#d97706", "#059669"],
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, data) => {
              const label = data.labels[tooltipItem.index] || "";
              const val = data.datasets[0].data[tooltipItem.index];
              const total = data.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return `${label}: ${val} cases (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (natureChartInstance.current) {
        natureChartInstance.current.destroy();
      }
    };
  }, [natureChartData]);

  // Render "Cases per Services Provided" row chart in descending order
  useEffect(() => {
    if (!servicesCanvasRef.current || !servicesChartData.labels.length) {
      return undefined;
    }

    if (servicesChartInstance.current) {
      servicesChartInstance.current.destroy();
    }

    const ctx = servicesCanvasRef.current.getContext("2d");

    servicesChartInstance.current = new Chart(ctx, {
      type: "horizontalBar",
      data: {
        labels: servicesChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: servicesChartData.open,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: servicesChartData.closed,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                display: false
              },
              ticks: {
                fontColor: "#1e293b",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (servicesChartInstance.current) {
        servicesChartInstance.current.destroy();
      }
    };
  }, [servicesChartData]);

  // Render "Cases per Incidents" bar chart with 45-degree value labels
  useEffect(() => {
    if (!incidentsCanvasRef.current || !incidentsChartData.labels.length) {
      return undefined;
    }

    if (incidentsChartInstance.current) {
      incidentsChartInstance.current.destroy();
    }

    const ctx = incidentsCanvasRef.current.getContext("2d");

    incidentsChartInstance.current = new Chart(ctx, {
      type: "bar",
      data: {
        labels: incidentsChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: incidentsChartData.open,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: incidentsChartData.closed,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#334155",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (incidentsChartInstance.current) {
        incidentsChartInstance.current.destroy();
      }
    };
  }, [incidentsChartData]);

  // Render "Cases per Vulnerabilities" bar chart with 45 degree rotated labels
  useEffect(() => {
    if (!vulnerabilitiesCanvasRef.current || !vulnerabilitiesChartData.labels.length) {
      return undefined;
    }

    if (vulnerabilitiesChartInstance.current) {
      vulnerabilitiesChartInstance.current.destroy();
    }

    const ctx = vulnerabilitiesCanvasRef.current.getContext("2d");

    vulnerabilitiesChartInstance.current = new Chart(ctx, {
      type: "bar",
      data: {
        labels: vulnerabilitiesChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: vulnerabilitiesChartData.open,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: vulnerabilitiesChartData.closed,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#334155",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (vulnerabilitiesChartInstance.current) {
        vulnerabilitiesChartInstance.current.destroy();
      }
    };
  }, [vulnerabilitiesChartData]);

  // Render "Cases per Diagnosed Disability" pie chart with inline labels
  useEffect(() => {
    if (!diagnosedDisabilityCanvasRef.current || !diagnosedDisabilityChartData.data.length) {
      return undefined;
    }

    if (diagnosedDisabilityChartInstance.current) {
      diagnosedDisabilityChartInstance.current.destroy();
    }

    const ctx = diagnosedDisabilityCanvasRef.current.getContext("2d");

    diagnosedDisabilityChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: diagnosedDisabilityChartData.labels,
        datasets: [
          {
            data: diagnosedDisabilityChartData.data,
            backgroundColor: diagnosedDisabilityChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (diagnosedDisabilityChartInstance.current) {
        diagnosedDisabilityChartInstance.current.destroy();
      }
    };
  }, [diagnosedDisabilityChartData]);

  // Render "Cases per Un-Diagnosed Disability" pie chart with inline labels
  useEffect(() => {
    if (!undiagnosedDisabilityCanvasRef.current || !undiagnosedDisabilityChartData.data.length) {
      return undefined;
    }

    if (undiagnosedDisabilityChartInstance.current) {
      undiagnosedDisabilityChartInstance.current.destroy();
    }

    const ctx = undiagnosedDisabilityCanvasRef.current.getContext("2d");

    undiagnosedDisabilityChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: undiagnosedDisabilityChartData.labels,
        datasets: [
          {
            data: undiagnosedDisabilityChartData.data,
            backgroundColor: undiagnosedDisabilityChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (undiagnosedDisabilityChartInstance.current) {
        undiagnosedDisabilityChartInstance.current.destroy();
      }
    };
  }, [undiagnosedDisabilityChartData]);

  // Render "Cases per District" bar chart with 45 degree rotated labels
  useEffect(() => {
    if (!districtCanvasRef.current || !districtChartData.labels.length) {
      return undefined;
    }

    if (districtChartInstance.current) {
      districtChartInstance.current.destroy();
    }

    const ctx = districtCanvasRef.current.getContext("2d");

    districtChartInstance.current = new Chart(ctx, {
      type: "bar",
      data: {
        labels: districtChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: districtChartData.open,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: districtChartData.closed,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#334155",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (districtChartInstance.current) {
        districtChartInstance.current.destroy();
      }
    };
  }, [districtChartData]);

  // Render "Cases per Tehsil" bar chart with 45 degree rotated labels
  useEffect(() => {
    if (!tehsilCanvasRef.current || !tehsilChartData.labels.length) {
      return undefined;
    }

    if (tehsilChartInstance.current) {
      tehsilChartInstance.current.destroy();
    }

    const ctx = tehsilCanvasRef.current.getContext("2d");

    tehsilChartInstance.current = new Chart(ctx, {
      type: "bar",
      data: {
        labels: tehsilChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: tehsilChartData.open,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: tehsilChartData.closed,
            barPercentage: 0.55,
            categoryPercentage: 0.75
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#334155",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (tehsilChartInstance.current) {
        tehsilChartInstance.current.destroy();
      }
    };
  }, [tehsilChartData]);

  // Render "Location of Incident" pie chart with inline labels
  useEffect(() => {
    if (!incidentLocationCanvasRef.current || !incidentLocationChartData.data.length) {
      return undefined;
    }

    if (incidentLocationChartInstance.current) {
      incidentLocationChartInstance.current.destroy();
    }

    const ctx = incidentLocationCanvasRef.current.getContext("2d");

    incidentLocationChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: incidentLocationChartData.labels,
        datasets: [
          {
            data: incidentLocationChartData.data,
            backgroundColor: incidentLocationChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (incidentLocationChartInstance.current) {
        incidentLocationChartInstance.current.destroy();
      }
    };
  }, [incidentLocationChartData]);

  // Render "Cases per Care Arrangement" pie chart with inline labels
  useEffect(() => {
    if (!careArrangementCanvasRef.current || !careArrangementChartData.data.length) {
      return undefined;
    }

    if (careArrangementChartInstance.current) {
      careArrangementChartInstance.current.destroy();
    }

    const ctx = careArrangementCanvasRef.current.getContext("2d");

    careArrangementChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: careArrangementChartData.labels,
        datasets: [
          {
            data: careArrangementChartData.data,
            backgroundColor: careArrangementChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (careArrangementChartInstance.current) {
        careArrangementChartInstance.current.destroy();
      }
    };
  }, [careArrangementChartData]);

  // Render "Cases per Caseworker" line chart with 45 degree rotated labels
  useEffect(() => {
    if (!caseWorkerCanvasRef.current || !caseWorkerChartData.labels.length) {
      return undefined;
    }

    if (caseWorkerChartInstance.current) {
      caseWorkerChartInstance.current.destroy();
    }

    const ctx = caseWorkerCanvasRef.current.getContext("2d");

    caseWorkerChartInstance.current = new Chart(ctx, {
      type: "line",
      data: {
        labels: caseWorkerChartData.labels,
        datasets: [
          {
            label: "Total Cases",
            borderColor: "#0284c7",
            backgroundColor: "rgba(2, 132, 199, 0.08)",
            pointBackgroundColor: "#0284c7",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#0284c7",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: true,
            data: caseWorkerChartData.total
          },
          {
            label: "Open Cases",
            borderColor: "#00c0f0",
            backgroundColor: "transparent",
            pointBackgroundColor: "#00c0f0",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#00c0f0",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: false,
            data: caseWorkerChartData.open
          },
          {
            label: "Closed Cases",
            borderColor: "#f02fc2",
            backgroundColor: "transparent",
            pointBackgroundColor: "#f02fc2",
            pointBorderColor: "#ffffff",
            pointHoverBackgroundColor: "#ffffff",
            pointHoverBorderColor: "#f02fc2",
            pointRadius: 4,
            pointHoverRadius: 6,
            borderWidth: 2.5,
            lineTension: 0.25,
            fill: false,
            data: caseWorkerChartData.closed
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: true,
          position: "bottom",
          labels: {
            usePointStyle: true,
            boxWidth: 8,
            padding: 20,
            fontColor: "#334155",
            fontSize: 13,
            fontStyle: "600"
          }
        },
        scales: {
          xAxes: [
            {
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                minRotation: 45,
                maxRotation: 45,
                autoSkip: false,
                fontColor: "#334155",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ],
          yAxes: [
            {
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (caseWorkerChartInstance.current) {
        caseWorkerChartInstance.current.destroy();
      }
    };
  }, [caseWorkerChartData]);

  // Render "Cases per Maritial Status" pie chart with inline labels
  useEffect(() => {
    if (!maritalStatusCanvasRef.current || !maritalStatusChartData.data.length) {
      return undefined;
    }

    if (maritalStatusChartInstance.current) {
      maritalStatusChartInstance.current.destroy();
    }

    const ctx = maritalStatusCanvasRef.current.getContext("2d");

    maritalStatusChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: maritalStatusChartData.labels,
        datasets: [
          {
            data: maritalStatusChartData.data,
            backgroundColor: maritalStatusChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (maritalStatusChartInstance.current) {
        maritalStatusChartInstance.current.destroy();
      }
    };
  }, [maritalStatusChartData]);

  // Render "Cases per Nationality" pie chart with inline labels
  useEffect(() => {
    if (!nationalityCanvasRef.current || !nationalityChartData.data.length) {
      return undefined;
    }

    if (nationalityChartInstance.current) {
      nationalityChartInstance.current.destroy();
    }

    const ctx = nationalityCanvasRef.current.getContext("2d");

    nationalityChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: nationalityChartData.labels,
        datasets: [
          {
            data: nationalityChartData.data,
            backgroundColor: nationalityChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (nationalityChartInstance.current) {
        nationalityChartInstance.current.destroy();
      }
    };
  }, [nationalityChartData]);

  // Render "Cases per Child getting Education" pie chart with inline labels
  useEffect(() => {
    if (!educationCanvasRef.current || !educationChartData.data.length) {
      return undefined;
    }

    if (educationChartInstance.current) {
      educationChartInstance.current.destroy();
    }

    const ctx = educationCanvasRef.current.getContext("2d");

    educationChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: educationChartData.labels,
        datasets: [
          {
            data: educationChartData.data,
            backgroundColor: educationChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (educationChartInstance.current) {
        educationChartInstance.current.destroy();
      }
    };
  }, [educationChartData]);

  // Render "Cases per Language" pie chart with inline labels
  useEffect(() => {
    if (!languageCanvasRef.current || !languageChartData.data.length) {
      return undefined;
    }

    if (languageChartInstance.current) {
      languageChartInstance.current.destroy();
    }

    const ctx = languageCanvasRef.current.getContext("2d");

    languageChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: languageChartData.labels,
        datasets: [
          {
            data: languageChartData.data,
            backgroundColor: languageChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (languageChartInstance.current) {
        languageChartInstance.current.destroy();
      }
    };
  }, [languageChartData]);

  // Render "Cases per Religion" pie chart with inline labels
  useEffect(() => {
    if (!religionCanvasRef.current || !religionChartData.data.length) {
      return undefined;
    }

    if (religionChartInstance.current) {
      religionChartInstance.current.destroy();
    }

    const ctx = religionCanvasRef.current.getContext("2d");

    religionChartInstance.current = new Chart(ctx, {
      type: "pie",
      plugins: [inlinePieLabelsPlugin],
      data: {
        labels: religionChartData.labels,
        datasets: [
          {
            data: religionChartData.data,
            backgroundColor: religionChartData.colors,
            borderWidth: 2,
            borderColor: "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        layout: {
          padding: {
            top: 25,
            bottom: 25,
            left: 48,
            right: 48
          }
        },
        legend: {
          display: false
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.labels[tooltipItem.index] || "";
              const val = chartData.datasets[0].data[tooltipItem.index] || 0;
              const total = chartData.datasets[0].data.reduce((acc, v) => acc + (v || 0), 0);
              const pct = Math.round((val / (total || 1)) * 100);

              return ` ${label}: ${val} (${pct}%)`;
            }
          }
        }
      }
    });

    return () => {
      if (religionChartInstance.current) {
        religionChartInstance.current.destroy();
      }
    };
  }, [religionChartData]);

  // Render "Cases per Age-Groups" row chart in descending order
  useEffect(() => {
    if (!ageGroupCanvasRef.current || !ageGroupChartData.labels.length) {
      return undefined;
    }

    if (ageGroupChartInstance.current) {
      ageGroupChartInstance.current.destroy();
    }

    const ctx = ageGroupCanvasRef.current.getContext("2d");

    ageGroupChartInstance.current = new Chart(ctx, {
      type: "horizontalBar",
      data: {
        labels: ageGroupChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: ageGroupChartData.open,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          },
          {
            label: "Closed Cases",
            backgroundColor: "#f02fc2",
            hoverBackgroundColor: "#d61fb0",
            data: ageGroupChartData.closed,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: false
        },
        scales: {
          xAxes: [
            {
              stacked: true,
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ],
          yAxes: [
            {
              stacked: true,
              gridLines: {
                display: false
              },
              ticks: {
                fontColor: "#1e293b",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ]
        },
        tooltips: {
          mode: "index",
          intersect: false
        }
      }
    });

    return () => {
      if (ageGroupChartInstance.current) {
        ageGroupChartInstance.current.destroy();
      }
    };
  }, [ageGroupChartData]);

  // Render "Cases per Workflow" row chart in defined order (open cases only)
  useEffect(() => {
    if (!workflowCanvasRef.current || !workflowChartData.labels.length) {
      return undefined;
    }

    if (workflowChartInstance.current) {
      workflowChartInstance.current.destroy();
    }

    const ctx = workflowCanvasRef.current.getContext("2d");

    workflowChartInstance.current = new Chart(ctx, {
      type: "horizontalBar",
      data: {
        labels: workflowChartData.labels,
        datasets: [
          {
            label: "Open Cases",
            backgroundColor: "#00c0f0",
            hoverBackgroundColor: "#00a5d2",
            data: workflowChartData.data,
            barPercentage: 0.7,
            categoryPercentage: 0.85
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 400 },
        legend: {
          display: false
        },
        scales: {
          xAxes: [
            {
              gridLines: {
                color: "#f1f5f9",
                zeroLineColor: "#cbd5e1"
              },
              ticks: {
                beginAtZero: true,
                fontColor: "#64748b",
                fontSize: 12,
                precision: 0
              }
            }
          ],
          yAxes: [
            {
              gridLines: {
                display: false
              },
              ticks: {
                fontColor: "#1e293b",
                fontSize: 12,
                fontStyle: "600"
              }
            }
          ]
        },
        tooltips: {
          callbacks: {
            label: (tooltipItem, chartData) => {
              const label = chartData.datasets[tooltipItem.datasetIndex].label || "";
              const val = tooltipItem.xLabel || 0;

              return ` ${label}: ${val}`;
            }
          }
        }
      }
    });

    return () => {
      if (workflowChartInstance.current) {
        workflowChartInstance.current.destroy();
      }
    };
  }, [workflowChartData]);

  const totalDisplay = getDisplayCount(loading, metrics.total);
  const openDisplay = getDisplayCount(loading, metrics.open);
  const closedDisplay = getDisplayCount(loading, metrics.closed);
  const openMaleDisplay = getDisplayCount(loading, metrics.openMale);
  const closedMaleDisplay = getDisplayCount(loading, metrics.closedMale);
  const openFemaleDisplay = getDisplayCount(loading, metrics.openFemale);
  const closedFemaleDisplay = getDisplayCount(loading, metrics.closedFemale);
  const openTransDisplay = getDisplayCount(loading, metrics.openTrans);
  const closedTransDisplay = getDisplayCount(loading, metrics.closedTrans);

  return (
    <div className={css.container}>
      {/* <div className={css.header}>
        <div className={css.headerContent}>
          <h1 className={css.title}>CPIMS Dashboard</h1>
        </div>
      </div> */}

      {error && <div className={css.errorText}>{error}</div>}

      {/* Row containing all 5 boxes with identical design (Total Cases has reduced width) */}
      <div className={css.boxesRow}>
        {/* 1. Total Cases Box */}
        <div className={`${css.card} ${css.totalCard}`}>
          <div className={css.cardHeader}>
            <h2 className={css.cardTitle} title="Total Cases">
              Total Cases
            </h2>
          </div>

          <div className={css.metricSection}>
            <div className={css.singleMetricWrapper}>
              <span className={css.singleMetricCount}>{totalDisplay}</span>
            </div>
          </div>
        </div>

        {/* 2. Case Status Box */}
        <div className={css.card}>
          <div className={css.cardHeader}>
            <h2 className={css.cardTitle} title="Total Cases per Status">
              Total Cases per Status
            </h2>
          </div>

          <div className={css.metricSection}>
            <div className={css.metricItem}>
              <span className={css.badgeOpen}>OPEN</span>
              <span className={css.metricCountOpen}>{openDisplay}</span>
            </div>
            <div className={css.metricItem}>
              <span className={css.badgeClosed}>CLOSED</span>
              <span className={css.metricCountClosed}>{closedDisplay}</span>
            </div>
          </div>
        </div>

        {/* 3. Male Cases Box */}
        <div className={css.card}>
          <div className={css.cardHeader}>
            <h2 className={css.cardTitle} title="Total Male Cases per Status">
              Total Male Cases per Status
            </h2>
          </div>

          <div className={css.metricSection}>
            <div className={css.metricItem}>
              <span className={css.badgeOpen}>OPEN</span>
              <span className={css.metricCountOpen}>{openMaleDisplay}</span>
            </div>
            <div className={css.metricItem}>
              <span className={css.badgeClosed}>CLOSED</span>
              <span className={css.metricCountClosed}>{closedMaleDisplay}</span>
            </div>
          </div>
        </div>

        {/* 4. Female Cases Box */}
        <div className={css.card}>
          <div className={css.cardHeader}>
            <h2 className={css.cardTitle} title="Total Female Cases per Status">
              Total Female Cases per Status
            </h2>
          </div>

          <div className={css.metricSection}>
            <div className={css.metricItem}>
              <span className={css.badgeOpen}>OPEN</span>
              <span className={css.metricCountOpen}>{openFemaleDisplay}</span>
            </div>
            <div className={css.metricItem}>
              <span className={css.badgeClosed}>CLOSED</span>
              <span className={css.metricCountClosed}>{closedFemaleDisplay}</span>
            </div>
          </div>
        </div>

        {/* 5. Transgender Cases Box */}
        <div className={css.card}>
          <div className={css.cardHeader}>
            <h2 className={css.cardTitle} title="Total Transgender Cases per Status">
              Total Transgender Cases per Status
            </h2>
          </div>

          <div className={css.metricSection}>
            <div className={css.metricItem}>
              <span className={css.badgeOpen}>OPEN</span>
              <span className={css.metricCountOpen}>{openTransDisplay}</span>
            </div>
            <div className={css.metricItem}>
              <span className={css.badgeClosed}>CLOSED</span>
              <span className={css.metricCountClosed}>{closedTransDisplay}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Row 1: Cases per Gender & Cases per Age-Groups */}
      <div className={css.chartsGrid}>
        {/* Left: Cases per Gender (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Gender</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={genderCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Age-Groups (Row Chart in order: 0-5, 6-9, 10-13, 14-18, 18+, Unknown) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Age-Groups">
            Cases per Age-Groups
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={ageGroupCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row 2: Cases per Month/Year */}
      <div className={css.timelineCard}>
        <h2 className={css.chartTitle}>Cases per Month/Year</h2>
        <div className={css.chartCanvasWrapper}>
          <canvas ref={timelineCanvasRef} />
        </div>
      </div>

      {/* Row 3: Cases per Workflow & Cases per Source of Information */}
      <div className={css.chartsGrid}>
        {/* Left: Cases per Workflow (Row Chart in defined workflow order, open cases only) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Workflow">
            Cases per Workflow
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={workflowCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Source of information (Row Chart in Descending Order) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Source of information</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={sourceCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row 4: Cases per Incidents & Cases per Vulnerabilities */}
      <div className={css.chartsGrid}>
        {/* Left: Cases per Incidents (Bar Chart) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Incidents</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={incidentsCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Vulnerabilities (Bar Chart) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Vulnerabilities</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={vulnerabilitiesCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row 5: Cases per Diagnosed Disability, Nature of Cases & Cases per Un-Diagnosed Disability */}
      <div className={css.chartsGridThree}>
        {/* Left: Cases per Diagnosed Disability (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Daignosed Disability">
            Cases per Diagnosed Disability
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={diagnosedDisabilityCanvasRef} />
          </div>
        </div>

        {/* Center: Nature of Cases (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Nature of Cases</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={natureCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Un-Diagnosed Disability (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Un-Daignosed Disability">
            Cases per Un-Diagnosed Disability
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={undiagnosedDisabilityCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row with Cases per District & Cases per Tehsil: in the same row, same height and width */}
      <div className={css.chartsGrid}>
        {/* Left: Cases per District (Bar Chart) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per District</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={districtCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Tehsil (Bar Chart) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Tehsil</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={tehsilCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row 7: Cases per Services Provided & Cases per Care Arrangement */}
      <div className={css.chartsGrid}>
        {/* Left: Cases per Services Provided (Row Chart in Descending Order) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Services Provided</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={servicesCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Care Arrangement (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Cases per Care Arrangement</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={careArrangementCanvasRef} />
          </div>
        </div>
      </div>

      {/* Cases per Caseworker: Line Chart below the existing charts */}
      <div className={css.timelineCard}>
        <h2 className={css.chartTitle} title="Cases per Caseworker">
          Cases per Caseworker
        </h2>
        <div className={css.chartCanvasWrapper}>
          <canvas ref={caseWorkerCanvasRef} />
        </div>
      </div>

      {/* Row 9: Location of Incident, Cases per Maritial Status & Cases per Nationality */}
      <div className={css.chartsGridThree}>
        {/* Left: Location of Incident (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle}>Location of Incident</h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={incidentLocationCanvasRef} />
          </div>
        </div>

        {/* Center: Cases per Maritial Status (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Maritial Status">
            Cases per Maritial Status
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={maritalStatusCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Nationality (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Nationality">
            Cases per Nationality
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={nationalityCanvasRef} />
          </div>
        </div>
      </div>

      {/* Row with Cases per Child getting Education, Cases per Language & Cases per Religion: all 3 in same row */}
      <div className={css.chartsGridThree}>
        {/* Left: Cases per Child getting Education (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Child getting Education">
            Cases per Child getting Education
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={educationCanvasRef} />
          </div>
        </div>

        {/* Center: Cases per Language (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Language">
            Cases per Language
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={languageCanvasRef} />
          </div>
        </div>

        {/* Right: Cases per Religion (Pie Chart with Inline Labels) */}
        <div className={css.chartCard}>
          <h2 className={css.chartTitle} title="Cases per Religion">
            Cases per Religion
          </h2>
          <div className={css.chartCanvasWrapper}>
            <canvas ref={religionCanvasRef} />
          </div>
        </div>
      </div>
    </div>
  );
}

NewDashboard.displayName = "NewDashboard";

export default NewDashboard;
