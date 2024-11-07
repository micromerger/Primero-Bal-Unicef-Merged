// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

import PropTypes from "prop-types";

function Component({ realPercent, label, index, css }) {
  const percentage = realPercent * 100;
  const style = { width: percentage > 0 ? `${percentage}%` : "auto" };

  return (
    <div key={index} className={css.StackedPercentageBarLabelContainer} style={style}>
      <div>
        <h1 className={css.StackedPercentageBarLabelPercentage}>{`${percentage.toFixed(0)}%`}</h1>
      </div>
      <div className={css.StackedPercentageBarLabel}>{label}</div>
    </div>
  );
}

Component.displayName = "StackedPercentageBarLabel";

Component.propTypes = {
  css: PropTypes.object,
  index: PropTypes.number,
  label: PropTypes.string,
  realPercent: PropTypes.number
};

export default Component;
