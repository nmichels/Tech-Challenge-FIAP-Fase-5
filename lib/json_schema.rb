module JsonSchema
  RISK_ITEM = {
    "type" => "array",
    "items" => {
      "type" => "object",
      "properties" => {
        "explanation" => { "type" => "string" },
        "resolution" => { "type" => "string" }
      },
      "required" => %w[explanation resolution],
      "additionalProperties" => false
    }
  }.freeze

  RISK_ANALYSIS = {
    "type" => "json_schema",
    "json_schema" => {
      "name" => "risk_analysis",
      "strict" => true,
      "schema" => {
        "type" => "object",
        "properties" => {
          "architecture_summary" => { "type" => "string" },
          "spoofing" => RISK_ITEM,
          "tampering" => RISK_ITEM,
          "repudiation" => RISK_ITEM,
          "information_disclosure" => RISK_ITEM,
          "denial_of_service" => RISK_ITEM,
          "elevation_of_privilege" => RISK_ITEM
        },
        "required" => %w[
          architecture_summary
          spoofing
          tampering
          repudiation
          information_disclosure
          denial_of_service
          elevation_of_privilege
        ],
        "additionalProperties" => false
      }
    }
  }.freeze
end
