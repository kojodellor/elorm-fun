-- ============================================================
-- Phase 1: Clinical Records Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. CLINICAL RECORDS
-- Full clerking data linked to a patient admission
CREATE TABLE IF NOT EXISTS clinical_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

  -- Type
  record_type TEXT NOT NULL DEFAULT 'obs', -- 'obs' | 'gynae'

  -- Demographics (supplement patients table)
  lmp DATE,
  edd_lmp DATE,
  edd_scan DATE,
  gestational_age TEXT,
  occupation TEXT,

  -- Presenting complaint
  presenting_complaint TEXT,
  hpc TEXT,

  -- ODQ responses (JSONB map of symptom -> boolean)
  odq JSONB DEFAULT '{}',
  -- Custom ODQ items added by user [{label, value}]
  odq_custom JSONB DEFAULT '[]',

  -- Systemic inquiry
  systemic_inquiry JSONB DEFAULT '{}',

  -- Obstetric history (array of pregnancies)
  obstetric_history JSONB DEFAULT '[]',
  booking_ga TEXT,

  -- Booking labs
  g6pd TEXT,
  sickling TEXT,
  vdrl TEXT,
  retroviral TEXT,
  hep_b TEXT,
  blood_group TEXT,
  booking_bp TEXT,
  booking_hb TEXT,

  -- Gynae history
  menstrual_history JSONB DEFAULT '{}',
  sexual_history JSONB DEFAULT '{}',
  contraceptive_history JSONB DEFAULT '{}',

  -- Past medical / drug / family / social history
  pmhx JSONB DEFAULT '{}',
  prev_admissions TEXT,
  prev_bt TEXT,
  prev_surgeries TEXT,
  current_medications TEXT,
  herbal_medications TEXT,
  allergies TEXT,
  family_history JSONB DEFAULT '{}',
  social_history JSONB DEFAULT '{}',

  -- Examination
  examination JSONB DEFAULT '{}',

  -- Investigations (array of investigation objects)
  investigations JSONB DEFAULT '[]',

  -- Impression & plan
  impression TEXT,
  plan TEXT,

  -- Meta
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. PATIENT REVIEWS
-- Daily, post-op, and ward reviews
CREATE TABLE IF NOT EXISTS patient_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  clinical_record_id UUID REFERENCES clinical_records(id),

  review_type TEXT NOT NULL, -- 'gynae' | 'obstetric' | 'postop_day1' | 'postop_day2' | 'postop_day3' | 'svd'
  review_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Complaints
  complaints TEXT,

  -- ODQ (reuse from admission, update as needed)
  odq JSONB DEFAULT '{}',

  -- Vitals
  vitals JSONB DEFAULT '{}', -- {pulse, bp, rr, spo2, temp}

  -- Examination findings
  examination JSONB DEFAULT '{}',

  -- Investigations
  investigations TEXT,

  -- Plan
  plan TEXT,

  -- Post-op specific
  postop_day INTEGER, -- 1, 2, 3...
  bowel_sounds_present BOOLEAN,
  catheter_removed BOOLEAN,
  oral_intake_started BOOLEAN,
  iv_antibiotics_switched BOOLEAN,
  wound_inspected BOOLEAN,

  -- Obstetric specific
  fetal_movement TEXT,
  contractions TEXT,
  liquor TEXT,
  bleeding TEXT,
  sfh TEXT,
  fhr TEXT,

  generated_note TEXT, -- cached generated note text

  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. THEATRE READINESS CHECKLIST
-- Per-patient readiness scoring for theatre
CREATE TABLE IF NOT EXISTS theatre_readiness_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  theatre_date DATE,

  -- Checklist items (all boolean)
  full_clerking_done BOOLEAN DEFAULT false,
  relevant_labs_done BOOLEAN DEFAULT false,
  blood_donated BOOLEAN DEFAULT false,
  cross_match_done BOOLEAN DEFAULT false,
  anaesthetic_review_done BOOLEAN DEFAULT false,
  medications_purchased BOOLEAN DEFAULT false,
  consent_signed BOOLEAN DEFAULT false,
  iv_cannula_set BOOLEAN DEFAULT false,
  nil_by_mouth_instructed BOOLEAN DEFAULT false,

  -- Auto-calculated 0-100
  readiness_score INTEGER GENERATED ALWAYS AS (
    (CASE WHEN full_clerking_done THEN 11 ELSE 0 END +
     CASE WHEN relevant_labs_done THEN 11 ELSE 0 END +
     CASE WHEN blood_donated THEN 11 ELSE 0 END +
     CASE WHEN cross_match_done THEN 12 ELSE 0 END +
     CASE WHEN anaesthetic_review_done THEN 12 ELSE 0 END +
     CASE WHEN medications_purchased THEN 11 ELSE 0 END +
     CASE WHEN consent_signed THEN 11 ELSE 0 END +
     CASE WHEN iv_cannula_set THEN 11 ELSE 0 END +
     CASE WHEN nil_by_mouth_instructed THEN 10 ELSE 0 END)
  ) STORED,

  notes TEXT,
  updated_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE clinical_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE theatre_readiness_checklist ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read all records
CREATE POLICY "auth_read_clinical_records"
  ON clinical_records FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "auth_insert_clinical_records"
  ON clinical_records FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "auth_update_clinical_records"
  ON clinical_records FOR UPDATE
  TO authenticated USING (true);

CREATE POLICY "auth_read_patient_reviews"
  ON patient_reviews FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "auth_insert_patient_reviews"
  ON patient_reviews FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = created_by);

CREATE POLICY "auth_update_patient_reviews"
  ON patient_reviews FOR UPDATE
  TO authenticated USING (true);

CREATE POLICY "auth_read_theatre_readiness"
  ON theatre_readiness_checklist FOR SELECT
  TO authenticated USING (true);

CREATE POLICY "auth_insert_theatre_readiness"
  ON theatre_readiness_checklist FOR INSERT
  TO authenticated WITH CHECK (true);

CREATE POLICY "auth_update_theatre_readiness"
  ON theatre_readiness_checklist FOR UPDATE
  TO authenticated USING (true);

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_clinical_records_patient ON clinical_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_reviews_patient ON patient_reviews(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_reviews_date ON patient_reviews(review_date);
CREATE INDEX IF NOT EXISTS idx_theatre_readiness_patient ON theatre_readiness_checklist(patient_id);
