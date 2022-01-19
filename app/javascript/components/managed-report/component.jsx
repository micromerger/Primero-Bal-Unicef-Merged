import { useEffect } from "react";
import { useDispatch } from "react-redux";
import PropTypes from "prop-types";
import { useLocation, useParams } from "react-router-dom";

import { useI18n } from "../i18n";
import PageContainer, { PageContent, PageHeading } from "../page";
import { ROUTES } from "../../config";
import { displayNameHelper, useMemoizedSelector } from "../../libs";
import { clearSelectedReport } from "../reports-form/action-creators";
import PageNavigation from "../page-navigation";
import ApplicationRoutes from "../application-routes";

import { getReport } from "./selectors";
import { fetchReport } from "./action-creators";
import { NAME } from "./constants";
import Exporter from "./components/exporter";

const violations = ["killing", "maiming", "attack on hospital"];

const Component = ({ routes }) => {
  const { id } = useParams();
  const i18n = useI18n();
  const dispatch = useDispatch();
  const { pathname } = useLocation();

  useEffect(() => {
    dispatch(fetchReport(id));

    return () => {
      dispatch(clearSelectedReport());
    };
  }, []);

  const menuList = violations.map(violation => ({
    to: `${ROUTES.managed_reports}/${id}/${violation}`,
    text: violation
  }));

  const report = useMemoizedSelector(state => getReport(state));

  const name = displayNameHelper(report.get("name"), i18n.locale);

  return (
    <PageContainer twoCol>
      <PageHeading title={name}>
        <Exporter includesGraph={report.get("graph")} />
      </PageHeading>
      <PageContent hasNav>
        <div>
          <PageNavigation menuList={menuList} selected={pathname} />
        </div>
        <div>
          <ApplicationRoutes routes={routes} />
        </div>
      </PageContent>
    </PageContainer>
  );
};

Component.displayName = NAME;

Component.propTypes = {
  routes: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default Component;
