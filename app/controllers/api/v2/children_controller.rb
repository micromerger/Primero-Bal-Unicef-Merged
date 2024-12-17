# frozen_string_literal: true

# Copyright (c) 2014 - 2023 UNICEF. All rights reserved.

# Main API controller for Case records
class Api::V2::ChildrenController < ApplicationApiController
  include Api::V2::Concerns::Pagination
  include Api::V2::Concerns::Record
  include Api::V2::Concerns::Referrable

  def traces
    authorize! :read, Child
    record = Child.includes(:matched_traces).find(params[:case_id])
    authorize! :read, record
    @traces = record.matched_traces
    render 'api/v2/traces/index'
  end
  alias select_updated_fields_super select_updated_fields
  def select_updated_fields
    changes = @record.saved_changes_to_record.keys
    @updated_field_names = select_updated_fields_super + @record.current_care_arrangements_changes(changes) +
                           @record.family_changes(changes)
  end
  def create_family
    authorize! :case_from_family, Child
    @current_record = Child.find(family_params[:case_id])
    @record = FamilyLinkageService.new_family_linked_child(
      current_user, @current_record, family_params[:family_detail_id]
    )
    @current_record.save! if @current_record.has_changes_to_save?
    @record.save!
    permit_fields
    select_fields_for_show
  end
  def family_params
    return @family_params if @family_params.present?

    data = params.require(:data).permit(:family_detail_id).to_h
    @family_params = data.merge(case_id: params.require(:case_id))
  end
  
  # def all
  #    cases = Child.all
  #    render json: cases, status: :ok
  # end

  # def all
  #   cases = Child.select("id, data, data->>'workflow' AS workflow, data->>'status' AS status").all
  #   render json: cases.map { |c| { id: c.id, workflow: c.workflow, status: c.status } }, status: :ok
  # end

  def all
    cases = Child.select("id, data, data->>'case_id_display' AS case_id_display, data->>'name' AS name, data->>'age' AS age, data->>'date_of_birth' AS date_of_birth, data->>'estimated' AS estimated, data->>'sex' AS sex,  data->>'language' AS language,  data->>'nationality' AS nationality, data->>'location_current' AS location_current, data->>'address_current' AS address_current, data->>'created_at' AS created_at, data->>'created_by' AS created_by, data->>'workflow' AS workflow, data->>'status' AS status, data->>'owned_by' AS owned_by, data->>'registration_date' AS registration_date, data->>'date_and_time_call_was_received__e11a2f3' AS date_and_time_call_was_received__e11a2f3, data->>'call_or_complaint_id_number_43383a7' AS call_or_complaint_id_number_43383a7, data->>'cp_helpline_officer_name_21c74de' AS cp_helpline_officer_name_21c74de, data->>'type_of_call_d30ea2b' AS type_of_call_d30ea2b, data->>'if_other__please_specify_d28af17' AS if_other__please_specify_d28af17, data->>'who_is_the_caller__65d1c9d' AS who_is_the_caller__65d1c9d, data->>'if_other__please_specify_82204b1' AS if_other__please_specify_82204b1, data->>'family_name_of_the_child_bec75f4' AS family_name_of_the_child_bec75f4, data->>'other_names_or_spelling_of_name_the_child_is_known_by_b1b0fc2' AS other_names_or_spelling_of_name_the_child_is_known_by_b1b0fc2, data->>'if_available__include_phone_number_6a5816a' AS if_available__include_phone_number_6a5816a, data->>'how_can_the_child_be_contacted__if_not_directly__specify_through_whom_fd66020' AS child_contact_through_whom, data->>'briefly_describe_the_child_s_situation_and_the_child_protection_risks_identified_at_the_time_of_the_call__43f4d3c' AS child_situation_at_the_time_of_call, data->>'protection_concerns' AS protection_concerns_incidents, data->>'if_other__please_specify_70bf2cc' AS other_incidents, data->>'vulnerabilities_57efd69' AS vulnerabilities, data->>'if_other__please_specify_bd01618' AS other_vulnerabilities, data->>'risk_level' AS risk_level, data->>'are_there_any_urgent_needs_that_require_an_immediate_response_from_the_social_caseworker_and_or_other_service_providers__0176118' AS immediate_reponse_required, data->>'if_yes__specify_urgent_needs_and_list_action_points_24h___48h_c8caa86' AS urgent_needs, data->>'cpu_to_which_the_case_is_referred_220fe0b' AS case_assigned_to_cpu, data->>'date_assigned_e2486ef' AS date_case_assigned, data->>'who_has_the_child_given_consent_or_assent_for_the_caseworker_to_contact__8336f67' AS consent_assent_taken_from, data->>'if_other__specify_details_ae8411f' AS consent_assent_taken_from_other, data->>'any_notes_on_these_contacts_or_who_not_to_contact_33ad50e' AS who_to_contact_or_not")
                 .where("data->>'record_state' = ?", 'true')
                 .all
    result = cases.map do |c|
      family_details = []
      if c.data['family_details_section'].present?
        family_details = c.data['family_details_section'].map do |family|
          {
            unique_id: family['unique_id'],
            relation: family['relation'],
            relation_name: family['relation_name'],
            relation_last_name: family['last_name_or_family_name_7ef2369'],
            relation_nickname: family['relation_nickname'],
            relation_sex: family['relation_sex'],
            relation_age: family['relation_age'],
            relation_date_of_birth: family['relation_date_of_birth'],
            relation_age_estimated: family['is_this_age_estimated__aac22b1'],
            relation_has_identification: family['does_the_family_member_have_identification__f783f54'],
            relation_id_type: family['if_yes__specify_type_of_identification_f2c1ac8'],
            relation_id_number: family['if_yes__specify_id_number_248fe69'],
            relation_nationality: family['relation_nationality'],
            relation_language: family['relation_language'],
            relation_religion: family['relation_religion'],
            relation_ethnicity: family['relation_ethnicity'],
            relation_occupation: family['occupation_4209ce4'],
            relation_is_alive: family['relation_is_alive'],
            relation_is_caregiver: family['relation_is_caregiver'],
            relation_death_details: family['relation_death_details'],
            relation_address_current: family['relation_address_current'],
            relation_location_current: family['relation_location_current'],
            relation_telephone: family['relation_telephone'],
            relation_is_legal_guardian: family['is_the_caregiver_the_legal_guardian_of_the_child__1336748'],
            legal_guardian_details: family['if_no__specify_who_is_the_legal_guardian_or_who_has_custody_over_the_child_f90665c'],
            relation_child_contact: family['if_the_mother_is_not_living_with_the_child__is_the_child_in_contact_with_the_mother_bb577bb'],
            relation_other_known_to_child: family['relation_other_family']
          }
        end
      end
      {
        id: c.id,
        case_id: c.case_id_display,
        name: c.name,
        age: c.age, date_of_birth: c.date_of_birth, age_estimated: c.estimated, sex: c.sex, language: c.language, nationality: c.nationality, location_current: c.location_current,address_current_living: c.address_current, created_at: c.created_at,  created_by: c.created_by, workflow: c.workflow, status: c.status, owned_by: c.owned_by, registration_date: c.registration_date, date_and_time_call_was_received: c.date_and_time_call_was_received__e11a2f3, call_or_complaint_id_number: c.call_or_complaint_id_number_43383a7, cp_helpline_officer_name: c.cp_helpline_officer_name_21c74de, type_of_call: c.type_of_call_d30ea2b, other_call_specify: c.if_other__please_specify_d28af17, who_is_the_caller: c.who_is_the_caller__65d1c9d, other_caller_specify: c.if_other__please_specify_82204b1, family_name_of_the_child: c.family_name_of_the_child_bec75f4, nickname_of_child: c.other_names_or_spelling_of_name_the_child_is_known_by_b1b0fc2, phone_number: c.if_available__include_phone_number_6a5816a, child_contact_through_whom: c.child_contact_through_whom, child_situation_at_the_time_of_call: c.child_situation_at_the_time_of_call, protection_concerns_incidents: c.protection_concerns_incidents, other_incidents: c.other_incidents, vulnerabilities: c.vulnerabilities, other_vulnerabilities: c.other_vulnerabilities, risk_level: c.risk_level, immediate_reponse_required: c.immediate_reponse_required, urgent_needs: c.urgent_needs, case_assigned_to_cpu: c.case_assigned_to_cpu, date_case_assigned: c.date_case_assigned, consent_assent_taken_from: c.consent_assent_taken_from, consent_assent_taken_from_other: c.consent_assent_taken_from_other, who_to_contact_or_not: c.who_to_contact_or_not,
        family_details: family_details
      }
    end
    render json: result, status: :ok
  end
end
