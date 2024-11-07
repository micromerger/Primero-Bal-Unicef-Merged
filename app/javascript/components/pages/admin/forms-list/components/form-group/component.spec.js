// Copyright (c) 2014 - 2023 UNICEF. All rights reserved.
import { mountedComponent, screen } from "test-utils";
import { DragDropContext, Droppable } from "react-beautiful-dnd";
import { Typography } from "@mui/material";

import FormGroup from "./component";

describe("<FormsList />/components/<FormGroup />", () => {
  function RenderFormGroup() {
    return (
      <DragDropContext>
        <Droppable droppableId="droppable" type="formGroup">
          {provided => (
            <div ref={provided.innerRef}>
              <FormGroup id="group-1" index={0} name="Group 1">
                <Typography>Some Content</Typography>
              </FormGroup>
            </div>
          )}
        </Droppable>
      </DragDropContext>
    );
  }

  RenderFormGroup.displayName = "RenderFormGroup";

  beforeEach(() => {
    mountedComponent(<RenderFormGroup />);
  });

  it("renders panel name", () => {
    expect(screen.getByText("Group 1")).toBeInTheDocument();
  });

  it("renders <DragIndicator />", () => {
    expect(screen.getByTestId("drag-indicator")).toBeInTheDocument();
  });
});
