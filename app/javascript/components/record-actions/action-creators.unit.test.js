import { expect } from "../../test/unit-test-helpers";

import { SET_DIALOG, SET_DIALOG_PENDING } from "./actions";
import * as actionCreators from "./action-creators";
import { REQUESTAPPROVAL } from "./constants";

describe("<RecordActions /> - Action Creators", () => {
  it("should have known action creators", () => {
    const creators = { ...actionCreators };

    expect(creators).to.have.property("setDialog");
    expect(creators).to.have.property("setPending");
    delete creators.setDialog;
    delete creators.setPending;

    expect(creators).to.be.empty;
  });

  it("should check that 'setDialog' action creator returns the correct object", () => {
    const args = {
      dialog: REQUESTAPPROVAL,
      open: true
    };

    const expectedAction = {
      type: SET_DIALOG,
      payload: { dialog: REQUESTAPPROVAL, open: true }
    };

    expect(actionCreators.setDialog(args)).to.deep.equal(expectedAction);
  });

  it("should check that 'setPending' action creator returns the correct object", () => {
    const args = {
      pending: true
    };

    const expectedAction = {
      type: SET_DIALOG_PENDING,
      payload: { pending: true }
    };

    expect(actionCreators.setPending(args)).to.deep.equal(expectedAction);
  });
});
