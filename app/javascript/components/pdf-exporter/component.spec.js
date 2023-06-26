import { fromJS } from "immutable";

import { mountedComponent, screen } from "../../test-utils";

import PdfExporter from "./component";

describe("<PdfExporter />", () => {
  const props = {
    agenciesWithLogosEnabled: [],
    currentUser: {},
    customFilenameField: "test",
    customFormProps: {
      condition: false,
      fields: [],
      title: ""
    },
    forms: [
      {
        id: 13,
        unique_id: "closure_form",
        description: {
          en: "Closure"
        },
        name: {
          en: "Closure"
        },
        visible: true,
        is_first_tab: false,
        order: 21,
        order_form_group: 120,
        parent_form: "case",
        editable: true,
        module_ids: ["primeromodule-cp", "primeromodule-gbv"],
        form_group_id: "closure",
        fields: [
          {
            name: "closure_approved",
            type: "tick_box",
            editable: false,
            disabled: true,
            visible: true,
            display_name: {
              en: "Approved by Manager"
            },
            help_text: {},
            multi_select: false,
            guiding_questions: "",
            required: false,
            date_validation: "default_date_validation",
            hide_on_view_page: false,
            date_include_time: false,
            subform_sort_by: "",
            show_on_minify_form: false,
            order: 0,
            tick_box_label: {
              en: "Yes"
            }
          }
        ],
        is_nested: false,
        subform_prevent_item_removal: false,
        collapsed_field_names: [],
        subform_append_only: false,
        initial_subforms: 0
      }
    ],
    formsSelectedField: "",
    formsSelectedFieldDefault: "",
    formsSelectedSelector: "",
    record: fromJS({}),
    ref: jest.fn()
  };

  it("renders PdfExporter", () => {
    mountedComponent(<PdfExporter {...props} />);
    screen.debug();

    expect(component.find(PdfExporter)).to.have.lengthOf(1);
  });

  it("renders Logos", () => {
    mountedComponent(<PdfExporter {...props} />);
    expect(screen.getByText(/exports.printed/i)).toBeInTheDocument();
    // const { component } = setupMockFormComponent(PdfExporter, { props });

    expect(component.find(Logos)).to.have.lengthOf(2);
  });

  it("renders RenderTable", () => {
    mountedComponent(<PdfExporter {...props} />);
    const { component } = setupMockFormComponent(PdfExporter, { props });

    expect(component.find(RenderTable)).to.have.lengthOf(1);
  });
});
