-- PostgreSQL Schema Dump
-- Database: fisa
-- Schemas: public, estimating, log, price_center, topology, warehouse
-- Generated on: 2025-12-05T16:42:28.612909

-- Schemas
CREATE SCHEMA IF NOT EXISTS estimating;
CREATE SCHEMA IF NOT EXISTS log;
CREATE SCHEMA IF NOT EXISTS price_center;
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS topology;
CREATE SCHEMA IF NOT EXISTS warehouse;

-- Types: Domains
CREATE DOMAIN topology.topoelement AS bigint[];
CREATE DOMAIN topology.topoelementarray AS bigint[];

-- Types: Enums
CREATE TYPE estimating.boq_item_type AS ENUM ('material', 'labor', 'equipment', 'service', 'other', 'group');
CREATE TYPE estimating.estimate_status AS ENUM ('draft', 'in_progress', 'pending_approval', 'finalized', 'archived');
CREATE TYPE price_center.price_list_status AS ENUM ('draft', 'effective', 'archived');
CREATE TYPE public.department_type AS ENUM ('technical', 'bidding', 'legal', 'finance', 'construction');
CREATE TYPE public.document_type AS ENUM ('design_drawing', 'pccc_approval', 'bid_invite', 'bid_submit', 'contract', 'acceptance');
CREATE TYPE public.integration_status AS ENUM ('active', 'inactive');
CREATE TYPE public.integration_type AS ENUM ('erp', 'crm', 'bim');
CREATE TYPE public.milestone_type AS ENUM ('design', 'construction', 'approval', 'testing', 'other');
CREATE TYPE public.notification_status AS ENUM ('sent', 'read');
CREATE TYPE public.package_type AS ENUM ('construction', 'equipment_supply', 'design', 'maintenance', 'other');
CREATE TYPE public.pl_method AS ENUM ('actual', 'forecast');
CREATE TYPE public.project_type AS ENUM ('construction_new', 'upgrade', 'equipment', 'service', 'other');
CREATE TYPE public.report_type AS ENUM ('project', 'package', 'contract', 'field');
CREATE TYPE public.rule_level AS ENUM ('success', 'info', 'warn', 'error');
CREATE TYPE public.rule_scope AS ENUM ('project', 'package', 'system');
CREATE TYPE public.scope_type AS ENUM ('module_specific', 'independent', 'system_wide');
CREATE TYPE public.signature_status AS ENUM ('unsigned', 'signed');
CREATE TYPE public.status_type AS ENUM ('draft', 'pending', 'approved', 'rejected', 'ongoing', 'completed', 'lead', 'bidding', 'ordered', 'planned', 'open', 'paused', 'archived');
CREATE TYPE public.task_priority AS ENUM ('low', 'medium', 'high');
CREATE TYPE public.task_status AS ENUM ('todo', 'in_progress', 'done');
CREATE TYPE public.trigger_type AS ENUM ('immediate', 'scheduled', 'event');
CREATE TYPE public.weather_type AS ENUM ('sunny', 'rainy', 'cloudy', 'intermittent');
CREATE TYPE public.wf_condition_type AS ENUM ('ALL_REQUIRED_TASKS_DONE', 'EXPR', 'default', 'expr', 'custom');
CREATE TYPE public.wf_instance_status AS ENUM ('draft', 'running', 'paused', 'completed', 'terminated', 'archived');
CREATE TYPE public.wf_offset_type AS ENUM ('none', 'from_step_start', 'from_step_end', 'from_project_start', 'from_milestone');
CREATE TYPE public.wf_priority AS ENUM ('low', 'medium', 'high');
CREATE TYPE public.wf_status AS ENUM ('draft', 'active', 'archived', 'published');
CREATE TYPE public.wf_step_status AS ENUM ('inactive', 'active', 'done', 'blocked', 'skipped', 'pending');
CREATE TYPE public.wf_step_type AS ENUM ('review', 'execution', 'integration', 'other', 'intake');
CREATE TYPE public.wf_task_status AS ENUM ('todo', 'in_progress', 'done', 'canceled');
CREATE TYPE public.wf_task_type AS ENUM ('human', 'approvalform', 'service', 'webhook', 'script', 'notification');
CREATE TYPE public.wf_transition_type AS ENUM ('forward', 'loopback', 'conditional');
CREATE TYPE public.wi_channel AS ENUM ('customer', 'internal', 'email', 'phone', 'chat', 'app');
CREATE TYPE public.wi_sla_status AS ENUM ('ok', 'breach_soon', 'breached', 'paused', 'na');

-- Tables
-- Table: estimating.boq_items
CREATE TABLE "estimating"."boq_items" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "estimate_version_id" uuid  NOT NULL,
  "parent_id" uuid  ,
  "line_no" character varying(64)  ,
  "item_code" character varying(128)  ,
  "item_name" text  NOT NULL,
  "item_type" USER-DEFINED DEFAULT 'material'::estimating.boq_item_type NOT NULL,
  "unit_id" uuid  ,
  "quantity" numeric(18,6) DEFAULT 0 NOT NULL,
  "unit_price" numeric(18,4) DEFAULT 0 NOT NULL,
  "amount" numeric(24,6)  ,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "metadata" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_audits
CREATE TABLE "estimating"."estimate_audits" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "estimate_id" uuid  NOT NULL,
  "estimate_version_id" uuid  ,
  "action" character varying(64)  NOT NULL,
  "actor_id" uuid  ,
  "details" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_preset_audits
CREATE TABLE "estimating"."estimate_preset_audits" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "preset_id" uuid  NOT NULL,
  "action" character varying(32)  NOT NULL,
  "actor_id" uuid  ,
  "snapshot" jsonb  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_preset_bindings
CREATE TABLE "estimating"."estimate_preset_bindings" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "preset_id" uuid  NOT NULL,
  "org_id" uuid  ,
  "project_id" uuid  ,
  "package_id" uuid  ,
  "is_default" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_presets
CREATE TABLE "estimating"."estimate_presets" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "name" character varying(255)  NOT NULL,
  "description" text  ,
  "scope" character varying(16)  NOT NULL,
  "vat_percent" numeric(7,4) DEFAULT 0 NOT NULL,
  "overhead_percent" numeric(7,4) DEFAULT 0 NOT NULL,
  "profit_percent" numeric(7,4) DEFAULT 0 NOT NULL,
  "rules" jsonb  NOT NULL,
  "visibility" jsonb  NOT NULL,
  "version" integer DEFAULT 1 NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_totals
CREATE TABLE "estimating"."estimate_totals" (
  "estimate_version_id" uuid  NOT NULL,
  "items_count" integer  ,
  "amount_material" numeric(24,6)  ,
  "amount_labor" numeric(24,6)  ,
  "amount_equipment" numeric(24,6)  ,
  "amount_service" numeric(24,6)  ,
  "overhead" numeric(24,6)  ,
  "tax" numeric(24,6)  ,
  "profit" numeric(24,6)  ,
  "total_amount" numeric(24,6)  ,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimate_versions
CREATE TABLE "estimating"."estimate_versions" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "estimate_id" uuid  NOT NULL,
  "version_no" integer  NOT NULL,
  "price_list_id" uuid  ,
  "is_finalized" boolean DEFAULT false NOT NULL,
  "is_locked" boolean DEFAULT false NOT NULL,
  "note" text  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: estimating.estimates
CREATE TABLE "estimating"."estimates" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "package_id" uuid  ,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "status" USER-DEFINED DEFAULT 'draft'::estimating.estimate_status NOT NULL,
  "owner_id" uuid  ,
  "external_ref" text  ,
  "description" text  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: log.audit_logs
CREATE TABLE "log"."audit_logs" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  ,
  "action" character varying(20)  ,
  "record_type" character varying(100)  ,
  "record_id" uuid  ,
  "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "details" jsonb  ,
);

-- Table: log.contracts
CREATE TABLE "log"."contracts" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" character varying(100)  ,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
  "start_date" date  ,
  "end_date" date  ,
  "value" numeric(15,2)  ,
  "file_url" character varying(512)  ,
  "workflow_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: price_center.effective_price_lists
CREATE TABLE "price_center"."effective_price_lists" (
  "id" uuid  NOT NULL,
  "price_list_code" text  NOT NULL,
  "name" text  NOT NULL,
  "status" text  NOT NULL,
  "description" text  ,
  "effective_from" date  NOT NULL,
  "effective_to" date  ,
  "unit_price" numeric  NOT NULL,
  "currency" text  NOT NULL,
  "vat_rate" numeric  ,
  "note" text  ,
  "supplier_id" uuid  NOT NULL,
  "supplier_code" text  NOT NULL,
  "supplier_name" text  NOT NULL,
  "material_id" uuid  NOT NULL,
  "item_code" text  NOT NULL,
  "material_name" text  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.labor_price_list_items
CREATE TABLE "price_center"."labor_price_list_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "labor_price_list_id" uuid  NOT NULL,
  "job_code" text  NOT NULL,
  "job_name" text  NOT NULL,
  "unit_id" uuid  ,
  "unit_price" numeric(18,2)  NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by_user_id" uuid  ,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_by_user_id" uuid  ,
  "unit" character varying(100)  ,
  "currency" character varying(100)  ,
  "status" character varying(100)  ,
  "note" text  ,
);

-- Table: price_center.labor_price_lists
CREATE TABLE "price_center"."labor_price_lists" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "org_id" uuid  ,
  "project_id" uuid  ,
  "code" text  ,
  "name" text  NOT NULL,
  "description" text  ,
  "effective_from" date  ,
  "effective_to" date  ,
  "status" text DEFAULT 'active'::text NOT NULL,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by_user_id" uuid  ,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_by_user_id" uuid  ,
  "note" text  ,
);

-- Table: price_center.material_categories
CREATE TABLE "price_center"."material_categories" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "parent_id" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.materials
CREATE TABLE "price_center"."materials" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "item_code" text  NOT NULL,
  "name" text  NOT NULL,
  "unit" text  NOT NULL,
  "category_id" uuid  ,
  "category_name" text  ,
  "brand" text  ,
  "spec" text  ,
  "last_price" numeric  ,
  "status" text  NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.outbox_events
CREATE TABLE "price_center"."outbox_events" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "event_type" text  NOT NULL,
  "aggregate_type" text  NOT NULL,
  "aggregate_id" uuid  ,
  "schema_source" text  NOT NULL,
  "payload" jsonb  NOT NULL,
  "headers" jsonb  ,
  "occurred_at" timestamp with time zone DEFAULT now() NOT NULL,
  "published_at" timestamp with time zone  ,
  "attempts" integer DEFAULT 0 NOT NULL,
  "producer" text DEFAULT 'c-service'::text NOT NULL,
  "status" text DEFAULT 'pending'::text NOT NULL,
);

-- Table: price_center.price_list_items
CREATE TABLE "price_center"."price_list_items" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "price_list_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "unit_id" uuid  NOT NULL,
  "unit_price" numeric(18,4)  NOT NULL,
  "tax_rate" numeric(7,4) DEFAULT 0 ,
  "metadata" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "item_code" character varying(100)  ,
  "item_name" character varying(500)  ,
  "unit" character varying(100)  ,
  "currency" character varying(100)  ,
  "status" character varying(100)  ,
);

-- Table: price_center.price_lists
CREATE TABLE "price_center"."price_lists" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "status" USER-DEFINED DEFAULT 'draft'::price_center.price_list_status NOT NULL,
  "valid_from" date  NOT NULL,
  "valid_to" date  ,
  "currency_code" character(3) DEFAULT 'VND'::bpchar NOT NULL,
  "source" character varying(255)  ,
  "created_by" uuid  ,
  "approved_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.supplier_quote_items
CREATE TABLE "price_center"."supplier_quote_items" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "supplier_quote_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "unit_id" uuid  NOT NULL,
  "unit_price" numeric(18,4)  NOT NULL,
  "min_qty" numeric(18,6)  ,
  "tax_rate" numeric(7,4) DEFAULT 0 ,
  "metadata" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.supplier_quotes
CREATE TABLE "price_center"."supplier_quotes" (
  "id" uuid  NOT NULL,
  "supplier_id" uuid  NOT NULL,
  "material_id" uuid  ,
  "item_code" text  NOT NULL,
  "quote_code" text  NOT NULL,
  "quote_date" date  NOT NULL,
  "unit_price" numeric  NOT NULL,
  "currency" text  NOT NULL,
  "vat_rate" numeric  ,
  "status" text  NOT NULL,
  "valid_from" date  ,
  "valid_to" date  ,
  "delivery_time" text  ,
  "warranty_months" integer  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.suppliers
CREATE TABLE "price_center"."suppliers" (
  "id" uuid  NOT NULL,
  "supplier_code" text  NOT NULL,
  "name" text  NOT NULL,
  "short_name" text  ,
  "contact_name" text  ,
  "phone" text  ,
  "email" text  ,
  "tax_code" text  ,
  "address" text  ,
  "province" text  ,
  "note" text  ,
  "rating" integer  ,
  "status" text  NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.unit_conversions
CREATE TABLE "price_center"."unit_conversions" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "from_unit_id" uuid  NOT NULL,
  "to_unit_id" uuid  NOT NULL,
  "factor" numeric(20,10)  NOT NULL,
  "is_linear" boolean DEFAULT true NOT NULL,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: price_center.units
CREATE TABLE "price_center"."units" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "symbol" character varying(32)  ,
  "base_unit_id" uuid  ,
  "dimension" character varying(64)  ,
  "decimals" integer DEFAULT 3 ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: public.approval_requests
CREATE TABLE "public"."approval_requests" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  ,
  "request_type" character varying(100)  ,
  "requested_by" uuid  ,
  "approver_id" uuid  ,
  "status" character varying(50) DEFAULT 'pending'::character varying ,
  "remarks" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.audit_logs
CREATE TABLE "public"."audit_logs" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  ,
  "action" character varying(20)  ,
  "record_type" character varying(100)  ,
  "record_id" uuid  ,
  "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "details" jsonb  ,
);

-- Table: public.configs
CREATE TABLE "public"."configs" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  ,
  "key" character varying(100)  NOT NULL,
  "value" jsonb  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "scope" text  ,
  "external_key" text  ,
  "is_active" boolean DEFAULT true ,
);

-- Table: public.contract_types
CREATE TABLE "public"."contract_types" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(50)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "description" text  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.contracts
CREATE TABLE "public"."contracts" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" character varying(100)  ,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
  "start_date" date  ,
  "end_date" date  ,
  "value" numeric(15,2)  ,
  "file_url" character varying(512)  ,
  "workflow_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "signature_status" USER-DEFINED DEFAULT 'unsigned'::signature_status ,
  "renewal_date" date  ,
  "payment_schedule" jsonb  ,
  "code" character varying(50)  ,
  "contract_type_id" uuid  ,
  "package_id" uuid  ,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
);

-- Table: public.departments
CREATE TABLE "public"."departments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "code" character varying(50)  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "is_active" boolean DEFAULT true ,
);

-- Table: public.document_comment_reactions
CREATE TABLE "public"."document_comment_reactions" (
  "comment_id" uuid  NOT NULL,
  "user_id" uuid  NOT NULL,
  "emoji" character varying(16) DEFAULT 'like'::character varying NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
);

-- Table: public.document_comments
CREATE TABLE "public"."document_comments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "document_id" uuid  NOT NULL,
  "version_id" uuid  ,
  "parent_id" uuid  ,
  "content" text  NOT NULL,
  "dept_code" character varying(50)  ,
  "mentioned" jsonb  ,
  "created_by" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "is_deleted" boolean DEFAULT false NOT NULL,
);

-- Table: public.document_types
CREATE TABLE "public"."document_types" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" text  NOT NULL,
  "name" text  NOT NULL,
  "description" text  ,
  "domain" text DEFAULT 'shared'::text NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "org_id" uuid  ,
  "sort_order" integer DEFAULT 0 ,
  "scope" character varying(50) DEFAULT 'project'::character varying ,
);

-- Table: public.document_versions
CREATE TABLE "public"."document_versions" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "document_id" uuid  NOT NULL,
  "version_no" integer  NOT NULL,
  "file_name" character varying(255)  NOT NULL,
  "file_url" character varying(2048)  NOT NULL,
  "size_bytes" bigint  ,
  "checksum" character varying(128)  ,
  "uploaded_by" uuid  ,
  "uploaded_at" timestamp with time zone DEFAULT now() NOT NULL,
  "change_log" text  ,
);

-- Table: public.documents
CREATE TABLE "public"."documents" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "package_id" uuid  ,
  "name" character varying(255)  NOT NULL,
  "department" USER-DEFINED  ,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
  "version" integer DEFAULT 1 ,
  "file_url" character varying(2048)  NOT NULL,
  "size_bytes" bigint  ,
  "owner_id" uuid  ,
  "deadline" timestamp with time zone  ,
  "workflow_id" uuid  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "permissions" jsonb  ,
  "doc_type" character varying(50)  ,
  "type_id" uuid  ,
);

-- Table: public.idempotency_keys
CREATE TABLE "public"."idempotency_keys" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "key" text  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "response_json" jsonb  ,
);

-- Table: public.notifications
CREATE TABLE "public"."notifications" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  ,
  "title" text  ,
  "body" text  ,
  "status" character varying(100)  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.organizations
CREATE TABLE "public"."organizations" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "name" character varying(255)  NOT NULL,
  "code" character varying(50)  ,
  "address" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.outbox_events
CREATE TABLE "public"."outbox_events" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "aggregate" text  ,
  "aggregate_id" uuid  ,
  "event_type" text  ,
  "payload" jsonb  ,
  "occurred_at" timestamp with time zone DEFAULT now() ,
  "processed_at" timestamp with time zone  ,
  "try_count" integer DEFAULT 0 ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "published_at" timestamp with time zone  ,
  "failed_attempts" integer DEFAULT 0 NOT NULL,
  "next_retry_at" timestamp with time zone  ,
  "last_error" text  ,
);

-- Table: public.packages
CREATE TABLE "public"."packages" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" USER-DEFINED  NOT NULL,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
  "start_date" date  ,
  "end_date" date  ,
  "budget" numeric(15,2)  ,
  "description" text  ,
  "workflow_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "progress" numeric(5,2) DEFAULT 0 ,
);

-- Table: public.project_members
CREATE TABLE "public"."project_members" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "user_id" uuid  NOT NULL,
  "role" character varying(100)  ,
  "is_active" boolean DEFAULT false ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "is_primary" boolean  ,
  "assigned_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "assigned_by" uuid  ,
  "permissions_override" jsonb  ,
  "joined_at" timestamp with time zone DEFAULT now() NOT NULL,
  "left_at" timestamp with time zone  ,
);

-- Table: public.projects
CREATE TABLE "public"."projects" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(50)  ,
  "name" character varying(255)  NOT NULL,
  "investor" character varying(255)  NOT NULL,
  "type" USER-DEFINED  NOT NULL,
  "start_date" date  NOT NULL,
  "end_date" date  ,
  "budget" numeric(15,2)  ,
  "address" text  NOT NULL,
  "scale" text  ,
  "org_id" uuid  NOT NULL,
  "workflow_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "description" text  ,
  "project_manager_id" uuid  ,
  "engineer_id" uuid  ,
  "accountant_id" uuid  ,
  "progress" numeric(5,2) DEFAULT 0 ,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
  "is_archived" boolean DEFAULT false NOT NULL,
);

-- Table: public.projects_deleted
CREATE TABLE "public"."projects_deleted" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "code" character varying(50)  ,
  "name" character varying(255)  NOT NULL,
  "investor" character varying(255)  NOT NULL,
  "type" USER-DEFINED  NOT NULL,
  "start_date" date  NOT NULL,
  "end_date" date  ,
  "budget" numeric(15,2)  ,
  "address" text  NOT NULL,
  "scale" text  ,
  "org_id" uuid  NOT NULL,
  "workflow_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "description" text  ,
  "project_manager_id" uuid  ,
  "engineer_id" uuid  ,
  "accountant_id" uuid  ,
  "progress" numeric(5,2) DEFAULT 0 ,
  "status" USER-DEFINED DEFAULT 'draft'::status_type ,
);

-- Table: public.ref_scopes
CREATE TABLE "public"."ref_scopes" (
  "code" text  NOT NULL,
  "name" text  NOT NULL,
  "note" text  ,
);

-- Table: public.refresh_tokens
CREATE TABLE "public"."refresh_tokens" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  NOT NULL,
  "token_hash" text  NOT NULL,
  "issued_at" timestamp with time zone DEFAULT now() NOT NULL,
  "expires_at" timestamp with time zone  NOT NULL,
  "revoked_at" timestamp with time zone  ,
  "replaced_by_token" uuid  ,
  "user_agent" text  ,
  "ip_address" inet  ,
);

-- Table: public.roles
CREATE TABLE "public"."roles" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "name" character varying(100)  NOT NULL,
  "permissions" jsonb  NOT NULL,
  "description" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.sla_policies
CREATE TABLE "public"."sla_policies" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "description" text  ,
  "targets" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "apply_rules" jsonb DEFAULT '[]'::jsonb NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "deleted_at" timestamp with time zone  ,
);

-- Table: public.spatial_ref_sys
CREATE TABLE "public"."spatial_ref_sys" (
  "srid" integer  NOT NULL,
  "auth_name" character varying(256)  ,
  "auth_srid" integer  ,
  "srtext" character varying(2048)  ,
  "proj4text" character varying(2048)  ,
);

-- Table: public.tags
CREATE TABLE "public"."tags" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  ,
  "domain" character varying(50) DEFAULT 'work_item'::character varying NOT NULL,
  "name" character varying(100)  NOT NULL,
  "slug" character varying(120)  NOT NULL,
  "color" character varying(20)  ,
  "description" text  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
);

-- Table: public.task_template_items
CREATE TABLE "public"."task_template_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "template_id" uuid  NOT NULL,
  "title" text  NOT NULL,
  "due_days_offset" integer  ,
  "default_owner_user_id" uuid  ,
  "default_executor_user_id" uuid  ,
  "required" boolean DEFAULT true NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: public.task_templates
CREATE TABLE "public"."task_templates" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "org_id" uuid  NOT NULL,
  "name" text  NOT NULL,
  "description" text  ,
  "default_assignee_user_id" uuid  ,
  "default_due_days" integer  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: public.tasks
CREATE TABLE "public"."tasks" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  ,
  "package_id" uuid  ,
  "name" character varying(255)  NOT NULL,
  "description" text  ,
  "priority" USER-DEFINED  ,
  "status" USER-DEFINED  ,
  "assigned_to" uuid  ,
  "start_date" date  ,
  "due_date" date  ,
  "progress" numeric(5,2) DEFAULT 0 ,
  "is_deleted" boolean DEFAULT false ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.tickets
CREATE TABLE "public"."tickets" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  ,
  "category" character varying(100)  ,
  "reporter_id" uuid  ,
  "assignee_id" uuid  ,
  "status" character varying(50) DEFAULT 'open'::character varying ,
  "priority" USER-DEFINED DEFAULT 'medium'::wf_priority ,
  "description" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.timeline_dependencies
CREATE TABLE "public"."timeline_dependencies" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "timeline_id" uuid  NOT NULL,
  "depends_on_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: public.timelines
CREATE TABLE "public"."timelines" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "milestone_name" character varying(255)  NOT NULL,
  "start_date" date  ,
  "end_date" date  ,
  "status" character varying(50) DEFAULT 'planned'::character varying ,
  "dependencies" jsonb  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "type" text  ,
  "priority" USER-DEFINED DEFAULT 'medium'::task_priority ,
  "assigned_to" uuid  ,
  "updated_by" uuid  ,
  "sort_order" integer  ,
  "is_deleted" boolean DEFAULT false ,
  "progress" integer DEFAULT 0 ,
  "source" text DEFAULT 'timeline'::text NOT NULL,
);

-- Table: public.timelines_backup_v1_6_clean
CREATE TABLE "public"."timelines_backup_v1_6_clean" (
  "id" uuid  ,
  "project_id" uuid  ,
  "milestone_name" character varying(255)  ,
  "start_date" date  ,
  "end_date" date  ,
  "status" character varying(50)  ,
  "dependencies" jsonb  ,
  "created_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "type" USER-DEFINED  ,
  "priority" USER-DEFINED  ,
  "assigned_to" uuid  ,
  "updated_by" uuid  ,
  "sort_order" integer  ,
  "is_deleted" boolean  ,
);

-- Table: public.user_departments
CREATE TABLE "public"."user_departments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  NOT NULL,
  "department_id" uuid  NOT NULL,
  "is_primary" boolean DEFAULT false ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "assigned_at" timestamp with time zone DEFAULT now() NOT NULL,
  "assigned_by" uuid  ,
  "removed_at" timestamp with time zone  ,
  "removed_by" uuid  ,
);

-- Table: public.user_devices
CREATE TABLE "public"."user_devices" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  NOT NULL,
  "platform" character varying(10)  NOT NULL,
  "fcm_token" text  ,
  "apns_token" text  ,
  "sns_endpoint_arn" text  ,
  "is_active" boolean DEFAULT true ,
  "device_model" text  ,
  "app_version" text  ,
  "last_seen_at" timestamp with time zone DEFAULT now() ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.user_preferences
CREATE TABLE "public"."user_preferences" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "user_id" uuid  NOT NULL,
  "project_id" uuid  ,
  "data" jsonb  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
);

-- Table: public.users
CREATE TABLE "public"."users" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "username" character varying(100)  NOT NULL,
  "password" character varying(255)  NOT NULL,
  "email" character varying(255)  NOT NULL,
  "full_name" character varying(255)  ,
  "role_id" uuid  NOT NULL,
  "org_id" uuid  NOT NULL,
  "phone" character varying(20)  ,
  "avatar_url" character varying(512)  ,
  "last_login" timestamp with time zone  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "title" text  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "employee_code" character varying  ,
);

-- Table: public.webhooks
CREATE TABLE "public"."webhooks" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  ,
  "event" character varying(100)  NOT NULL,
  "callback_url" character varying(512)  NOT NULL,
  "is_active" boolean DEFAULT true ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
);

-- Table: public.wi_categories
CREATE TABLE "public"."wi_categories" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "code" character varying(64)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "parent_id" uuid  ,
  "description" text  ,
  "order_no" integer DEFAULT 0 NOT NULL,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "deleted_at" timestamp with time zone  ,
  "name_norm" text  ,
  "level" integer  ,
  "children_count" integer  ,
  "template_code" character varying(128)  ,
  "form_key" character varying(128)  ,
  "default_type" character varying(32)  ,
);

-- Table: public.wi_sla_pauses
CREATE TABLE "public"."wi_sla_pauses" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  NOT NULL,
  "policy_id" uuid  ,
  "reason" text  ,
  "started_at" timestamp with time zone DEFAULT now() NOT NULL,
  "ended_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
);

-- Table: public.work_item_attachments
CREATE TABLE "public"."work_item_attachments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  NOT NULL,
  "object_storage_key" text  NOT NULL,
  "file_name" text  ,
  "content_type" character varying(150)  ,
  "size" bigint  ,
  "uploaded_by" uuid  ,
  "uploaded_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "note" text  ,
  "created_by" uuid  ,
  "created_at" timestamp with time zone  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "url" text  ,
);

-- Table: public.work_item_comments
CREATE TABLE "public"."work_item_comments" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  NOT NULL,
  "author_id" uuid  NOT NULL,
  "body" text  NOT NULL,
  "is_internal" boolean DEFAULT false ,
  "time_spent_minutes" integer  ,
  "created_at" timestamp with time zone DEFAULT now() ,
);

-- Table: public.work_item_idempotency
CREATE TABLE "public"."work_item_idempotency" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "idem_key" text  NOT NULL,
  "org_id" uuid  ,
  "user_id" uuid  ,
  "route" text DEFAULT '/api/v1/crm/work-items'::text ,
  "request_hash" text  ,
  "status_code" integer  ,
  "response_json" jsonb  ,
  "work_item_id" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "expires_at" timestamp with time zone  ,
  "is_processing" boolean DEFAULT false NOT NULL,
);

-- Table: public.work_item_state_history
CREATE TABLE "public"."work_item_state_history" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  NOT NULL,
  "from_status" text  ,
  "to_status" text  ,
  "by_user" uuid  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.work_item_tags
CREATE TABLE "public"."work_item_tags" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "work_item_id" uuid  NOT NULL,
  "tag" character varying(100)  NOT NULL,
  "created_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: public.work_item_watchers
CREATE TABLE "public"."work_item_watchers" (
  "work_item_id" uuid  NOT NULL,
  "user_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "id" uuid DEFAULT uuid_generate_v4() ,
);

-- Table: public.work_items
CREATE TABLE "public"."work_items" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "ref_code" character varying(100)  ,
  "ref_type" character varying(50)  NOT NULL,
  "project_id" uuid  ,
  "org_id" uuid  ,
  "title" character varying(255)  ,
  "description" text  ,
  "status" character varying(50) DEFAULT 'draft'::character varying ,
  "priority" USER-DEFINED DEFAULT 'medium'::wf_priority ,
  "created_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "ref_scope" text DEFAULT 'independent'::text NOT NULL,
  "ref_id" uuid  ,
  "data" jsonb  ,
  "type" character varying(100)  ,
  "code" character varying(100)  ,
  "channel" character varying(100)  ,
  "category_id" uuid  ,
  "subcategory_id" uuid  ,
  "requester_id" uuid  ,
  "assignee_id" uuid  ,
  "department_id" uuid  ,
  "due_at" timestamp with time zone  ,
  "sla_status" USER-DEFINED DEFAULT 'ok'::wi_sla_status ,
  "sla_policy_id" uuid  ,
  "time_spent_total" integer  ,
  "closed_at" timestamp with time zone  ,
  "is_deleted" boolean DEFAULT false ,
  "tags" jsonb  ,
  "scope_type" text  ,
  "scope_entity_id" uuid  ,
  "workflow_instance_id" uuid  ,
  "workflow_template_id" uuid  ,
  "workflow_template_code" text  ,
  "applied_binding_id" uuid  ,
);

-- Table: public.workflow_bindings
CREATE TABLE "public"."workflow_bindings" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "work_item_type" character varying(50)  NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "org_id" uuid  ,
  "category_id" uuid  ,
  "subcategory_id" uuid  ,
  "updated_at" timestamp with time zone  ,
  "is_active" boolean DEFAULT true ,
  "department_id" uuid  ,
);

-- Table: public.workflow_graph_layouts
CREATE TABLE "public"."workflow_graph_layouts" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "step_template_id" uuid  ,
  "x" numeric(10,2)  ,
  "y" numeric(10,2)  ,
  "ui_meta" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "layout_json" jsonb DEFAULT '{"edges": [], "nodes": [], "viewport": {"zoom": 1, "pan_x": 0, "pan_y": 0}}'::jsonb NOT NULL,
);

-- Table: public.workflow_instance_journal
CREATE TABLE "public"."workflow_instance_journal" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "instance_id" uuid  NOT NULL,
  "from_step_template_id" uuid  ,
  "to_step_template_id" uuid  ,
  "transition_id" uuid  ,
  "triggered_by" uuid  ,
  "trigger_type" character varying(50)  ,
  "matched_condition_json" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "note" text  ,
);

-- Table: public.workflow_instance_steps
CREATE TABLE "public"."workflow_instance_steps" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "instance_id" uuid  NOT NULL,
  "step_template_id" uuid  NOT NULL,
  "name" character varying(255)  ,
  "status" USER-DEFINED DEFAULT 'pending'::wf_step_status NOT NULL,
  "started_at" timestamp with time zone  ,
  "completed_at" timestamp with time zone  ,
  "owner_user_id" uuid  ,
  "owner_role" character varying(100)  ,
  "deadline" timestamp with time zone  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone DEFAULT now() ,
  "due_date" date  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.workflow_instance_tasks
CREATE TABLE "public"."workflow_instance_tasks" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "step_instance_id" uuid  NOT NULL,
  "task_template_id" uuid  NOT NULL,
  "name" character varying(255)  ,
  "status" USER-DEFINED DEFAULT 'todo'::wf_task_status NOT NULL,
  "required" boolean DEFAULT true NOT NULL,
  "assignee_id" uuid  ,
  "due_date" timestamp with time zone  ,
  "completed_at" timestamp with time zone  ,
  "actual_effort_hours" integer  ,
  "notes" text  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone DEFAULT now() ,
  "started_at" timestamp with time zone  ,
  "priority" USER-DEFINED DEFAULT 'medium'::wf_priority NOT NULL,
);

-- Table: public.workflow_instances
CREATE TABLE "public"."workflow_instances" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "name" character varying(255)  ,
  "version" character varying(50) DEFAULT 'v1'::character varying NOT NULL,
  "status" USER-DEFINED DEFAULT 'running'::wf_instance_status NOT NULL,
  "started_at" timestamp with time zone DEFAULT now() ,
  "completed_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "updated_at" timestamp with time zone DEFAULT now() ,
  "work_item_id" uuid  ,
  "owner_id" uuid  ,
  "current_step_id" uuid  ,
  "current_step_due_date" date  ,
);

-- Table: public.workflow_project_bindings
CREATE TABLE "public"."workflow_project_bindings" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "project_id" uuid  NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "workflow_template_version" integer  NOT NULL,
  "status" character varying(16) DEFAULT 'active'::character varying NOT NULL,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
  "updated_by" uuid  ,
);

-- Table: public.workflow_step_assignments
CREATE TABLE "public"."workflow_step_assignments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "workflow_step_id" uuid  NOT NULL,
  "department_id" uuid  ,
  "user_id" uuid  ,
  "role_in_step" character varying(20)  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: public.workflow_step_task_templates
CREATE TABLE "public"."workflow_step_task_templates" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "workflow_step_id" uuid  NOT NULL,
  "template_id" uuid  NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid  ,
);

-- Table: public.workflow_step_templates
CREATE TABLE "public"."workflow_step_templates" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" USER-DEFINED  NOT NULL,
  "owner_role" character varying(100)  NOT NULL,
  "expected_duration_days" integer  ,
  "order" integer DEFAULT 0 ,
  "description" text  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "sort_order" integer DEFAULT 0 ,
  "code" text  ,
  "step_key" text  ,
  "title" text  ,
  "color" text  ,
  "auto_advance" boolean DEFAULT false ,
  "role_id" uuid  ,
  "sla_days" integer DEFAULT 0 ,
  "sla_type" text DEFAULT 'd'::text ,
  "is_start" boolean DEFAULT false ,
  "is_end" boolean DEFAULT false ,
  "is_deleted" boolean DEFAULT false ,
  "external_key" text  ,
  "kind" character varying(20)  ,
  "form_schema_json" jsonb  ,
  "form_ui_schema_json" jsonb  ,
  "form_defaults_json" jsonb  ,
  "form_validations_json" jsonb  ,
);

-- Table: public.workflow_steps
CREATE TABLE "public"."workflow_steps" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_id" uuid  NOT NULL,
  "step_number" integer  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "assignees" jsonb  ,
  "watchers" jsonb  ,
  "doers" jsonb  ,
  "completion_conditions" jsonb  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
);

-- Table: public.workflow_task_templates
CREATE TABLE "public"."workflow_task_templates" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "step_template_id" uuid  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" text  NOT NULL,
  "assignee_role" character varying(100)  NOT NULL,
  "required" boolean DEFAULT true NOT NULL,
  "priority" USER-DEFINED DEFAULT 'medium'::wf_priority NOT NULL,
  "effort_hours" integer  ,
  "offset_type" USER-DEFINED DEFAULT 'none'::wf_offset_type NOT NULL,
  "offset_value" character varying(16)  ,
  "order" integer DEFAULT 1 NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
  "order_index" integer DEFAULT 0 ,
  "description" text  ,
  "default_duration_days" integer  ,
  "assignee_role_id" uuid  ,
  "is_deleted" boolean DEFAULT false ,
  "external_key" character varying(100)  ,
);

-- Table: public.workflow_template_edges
CREATE TABLE "public"."workflow_template_edges" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "template_id" uuid  ,
  "external_key" text  ,
  "from_node_id" uuid  ,
  "to_node_id" uuid  ,
  "name" character varying(255)  ,
  "type" character varying(100)  ,
  "is_default" boolean DEFAULT true ,
  "is_deleted" boolean DEFAULT false ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.workflow_template_nodes
CREATE TABLE "public"."workflow_template_nodes" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "template_id" uuid  ,
  "external_key" text  ,
  "name" character varying(255)  ,
  "type" character varying(100)  ,
  "is_deleted" boolean DEFAULT false ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: public.workflow_templates
CREATE TABLE "public"."workflow_templates" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "name" character varying(255)  NOT NULL,
  "version" character varying(50) DEFAULT 'v1'::character varying NOT NULL,
  "status" USER-DEFINED DEFAULT 'draft'::wf_status NOT NULL,
  "description" text  ,
  "created_by" uuid  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "scope_type" character varying(50) DEFAULT 'project'::character varying ,
  "code" character varying(100)  ,
  "is_deleted" boolean DEFAULT false ,
  "defaults_json" jsonb  ,
  "published_at" timestamp with time zone  ,
);

-- Table: public.workflow_transitions
CREATE TABLE "public"."workflow_transitions" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "workflow_template_id" uuid  NOT NULL,
  "from_step_template_id" uuid  NOT NULL,
  "to_step_template_id" uuid  NOT NULL,
  "transition_type" USER-DEFINED DEFAULT 'forward'::wf_transition_type NOT NULL,
  "label" character varying(255)  ,
  "is_default" boolean DEFAULT false NOT NULL,
  "condition_type" USER-DEFINED DEFAULT 'ALL_REQUIRED_TASKS_DONE'::wf_condition_type NOT NULL,
  "condition_json" jsonb  ,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone  ,
  "layout" jsonb  ,
  "order_index" integer  ,
  "from_step_id" uuid  ,
  "to_step_id" uuid  ,
  "outcome" character varying(100)  ,
  "policy_type" character varying(50)  ,
  "policy_json" jsonb  ,
  "auto_trigger" boolean DEFAULT false ,
  "is_deleted" boolean DEFAULT false ,
  "external_key" character varying(100)  ,
);

-- Table: public.workflows
CREATE TABLE "public"."workflows" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "name" character varying(255)  NOT NULL,
  "type" character varying(50)  ,
  "project_type" USER-DEFINED  ,
  "package_type" USER-DEFINED  ,
  "trigger_event" character varying(50)  ,
  "conditions" jsonb  ,
  "steps" jsonb  ,
  "scope" USER-DEFINED DEFAULT 'project'::rule_scope ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "created_by" uuid  ,
  "updated_by" uuid  ,
);

-- Table: topology.layer
CREATE TABLE "topology"."layer" (
  "topology_id" integer  NOT NULL,
  "layer_id" integer  NOT NULL,
  "schema_name" character varying  NOT NULL,
  "table_name" character varying  NOT NULL,
  "feature_column" character varying  NOT NULL,
  "feature_type" integer  NOT NULL,
  "level" integer DEFAULT 0 NOT NULL,
  "child_id" integer  ,
);

-- Table: topology.topology
CREATE TABLE "topology"."topology" (
  "id" integer DEFAULT nextval('topology_id_seq'::regclass) NOT NULL,
  "name" character varying  NOT NULL,
  "srid" integer  NOT NULL,
  "precision" double precision  NOT NULL,
  "hasz" boolean DEFAULT false NOT NULL,
  "useslargeids" boolean DEFAULT false NOT NULL,
);

-- Table: warehouse.inventory_balances
CREATE TABLE "warehouse"."inventory_balances" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "qty_on_hand" numeric(18,3) DEFAULT 0 NOT NULL,
  "qty_reserved" numeric(18,3) DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
);

-- Table: warehouse.issue_headers
CREATE TABLE "warehouse"."issue_headers" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "work_item_id" uuid  ,
  "mr_id" uuid  ,
  "code" character varying(50)  ,
  "issue_date" date DEFAULT CURRENT_DATE ,
  "status" character varying(50)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.issue_lines
CREATE TABLE "warehouse"."issue_lines" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "issue_id" uuid  NOT NULL,
  "mr_line_id" uuid  ,
  "material_id" uuid  NOT NULL,
  "uom" character varying(50)  ,
  "qty_issued" numeric(18,3)  NOT NULL,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.locations
CREATE TABLE "warehouse"."locations" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "code" character varying(50)  NOT NULL,
  "zone" character varying(50)  ,
  "rack" character varying(50)  ,
  "level" character varying(50)  ,
  "position" character varying(50)  ,
  "type" character varying(50)  ,
  "status" character varying(50)  ,
  "max_capacity_points" numeric(18,3)  ,
  "max_volume" numeric(18,3)  ,
  "max_weight" numeric(18,3)  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.mr_headers
CREATE TABLE "warehouse"."mr_headers" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "warehouse_id" uuid  ,
  "work_item_id" uuid  NOT NULL,
  "code" character varying(50)  ,
  "request_type" character varying(50)  ,
  "needed_date" date  ,
  "priority" character varying(50)  ,
  "status" character varying(50)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "package_id" uuid  ,
  "area_building" character varying(100)  ,
  "area_floor" character varying(100)  ,
  "area_zone" character varying(100)  ,
);

-- Table: warehouse.mr_lines
CREATE TABLE "warehouse"."mr_lines" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "mr_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "uom" character varying(50)  ,
  "qty_requested" numeric(18,3)  NOT NULL,
  "qty_approved" numeric(18,3)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.pallet_items
CREATE TABLE "warehouse"."pallet_items" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "pallet_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "qty_on_hand" numeric(18,3) DEFAULT 0 NOT NULL,
  "qty_reserved" numeric(18,3) DEFAULT 0 NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "updated_at" timestamp with time zone  ,
  "origin" character varying(100)  ,
  "standard_code" character varying(100)  ,
  "spec_text" text  ,
  "last_receipt_line_id" uuid  ,
);

-- Table: warehouse.pallet_movements
CREATE TABLE "warehouse"."pallet_movements" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "pallet_id" uuid  NOT NULL,
  "from_location_id" uuid  ,
  "to_location_id" uuid  ,
  "movement_type" character varying(50)  NOT NULL,
  "ref_receipt_id" uuid  ,
  "ref_issue_id" uuid  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "material_id" uuid  ,
  "qty" numeric(18,3)  ,
  "ref_transfer_id" uuid  ,
);

-- Table: warehouse.pallets
CREATE TABLE "warehouse"."pallets" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "location_id" uuid  ,
  "code" character varying(50)  NOT NULL,
  "pallet_type" character varying(50)  ,
  "status" character varying(50)  ,
  "max_capacity_points" numeric(18,3)  ,
  "max_volume" numeric(18,3)  ,
  "max_weight" numeric(18,3)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.receipt_headers
CREATE TABLE "warehouse"."receipt_headers" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "work_item_id" uuid  ,
  "source_type" character varying(50)  ,
  "source_id" uuid  ,
  "code" character varying(50)  ,
  "receipt_date" date DEFAULT CURRENT_DATE ,
  "status" character varying(50)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "source_ref_no" character varying(100)  ,
  "supplier_id" uuid  ,
  "building" character varying(100)  ,
  "floor" character varying(100)  ,
  "project_zone" character varying(100)  ,
  "project_area" character varying(100)  ,
);

-- Table: warehouse.receipt_lines
CREATE TABLE "warehouse"."receipt_lines" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "receipt_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "uom" character varying(50)  ,
  "qty_expected" numeric(18,3)  ,
  "qty_received" numeric(18,3)  NOT NULL,
  "location_id" uuid  ,
  "pallet_id" uuid  ,
  "status" character varying(50)  ,
  "note" text  ,
  "source_issue_line_id" uuid  ,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
  "boq_item_id" uuid  ,
  "contract_qty" numeric(18,3)  ,
  "issued_qty_to_date" numeric(18,3)  ,
  "remaining_qty" numeric(18,3)  ,
  "origin" character varying(100)  ,
  "standard_code" character varying(100)  ,
  "spec_text" text  ,
  "material_category" character varying(100)  ,
  "source_work_item_id" uuid  ,
  "source_work_item_line_id" uuid  ,
  "source_mr_id" uuid  ,
  "source_mr_line_id" uuid  ,
);

-- Table: warehouse.stocktake_headers
CREATE TABLE "warehouse"."stocktake_headers" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  NOT NULL,
  "warehouse_id" uuid  NOT NULL,
  "code" character varying(50)  ,
  "mode" character varying(30)  NOT NULL,
  "status" character varying(30)  NOT NULL,
  "scope_zone" character varying(50)  ,
  "scope_location_from" character varying(50)  ,
  "scope_location_to" character varying(50)  ,
  "note" text  ,
  "created_at" timestamp with time zone DEFAULT now() ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Table: warehouse.stocktake_lines
CREATE TABLE "warehouse"."stocktake_lines" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "stocktake_id" uuid  NOT NULL,
  "material_id" uuid  NOT NULL,
  "pallet_id" uuid  ,
  "location_id" uuid  ,
  "uom" character varying(50)  ,
  "qty_system" numeric(18,3)  NOT NULL,
  "qty_counted" numeric(18,3)  ,
  "variance_qty" numeric(18,3)  ,
  "note" text  ,
);

-- Table: warehouse.warehouses
CREATE TABLE "warehouse"."warehouses" (
  "id" uuid DEFAULT uuid_generate_v4() NOT NULL,
  "org_id" uuid  NOT NULL,
  "project_id" uuid  ,
  "code" character varying(50)  NOT NULL,
  "name" character varying(255)  NOT NULL,
  "description" text  ,
  "type" character varying(50)  ,
  "address" text  ,
  "is_active" boolean DEFAULT true NOT NULL,
  "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP ,
  "created_by" uuid  ,
  "updated_at" timestamp with time zone  ,
  "updated_by" uuid  ,
);

-- Views
CREATE OR REPLACE VIEW estimating.vw_estimates_list AS  SELECT e.id,
    e.project_id,
    e.code,
    e.name,
    e.status AS estimate_status,
    p.name AS project_name,
    pk.name AS package_name,
    u.full_name AS owner_name,
    ev.version_no AS latest_version_no,
    ('v'::text || (ev.version_no)::text) AS latest_version,
    ev.is_finalized AS latest_is_finalized,
    et.total_amount AS latest_total_amount,
    GREATEST(e.updated_at, ev.updated_at) AS last_activity_at
   FROM (((((estimating.estimates e
     LEFT JOIN projects p ON ((p.id = e.project_id)))
     LEFT JOIN packages pk ON ((pk.id = e.package_id)))
     LEFT JOIN users u ON ((u.id = e.owner_id)))
     LEFT JOIN LATERAL ( SELECT ev1.id,
            ev1.estimate_id,
            ev1.version_no,
            ev1.price_list_id,
            ev1.is_finalized,
            ev1.is_locked,
            ev1.note,
            ev1.created_by,
            ev1.updated_by,
            ev1.created_at,
            ev1.updated_at
           FROM estimating.estimate_versions ev1
          WHERE (ev1.estimate_id = e.id)
          ORDER BY ev1.version_no DESC
         LIMIT 1) ev ON (true))
     LEFT JOIN estimating.estimate_totals et ON ((et.estimate_version_id = ev.id)));;
CREATE OR REPLACE VIEW public.geography_columns AS  SELECT current_database() AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geography_column,
    postgis_typmod_dims(a.atttypmod) AS coord_dimension,
    postgis_typmod_srid(a.atttypmod) AS srid,
    postgis_typmod_type(a.atttypmod) AS type
   FROM pg_class c,
    pg_attribute a,
    pg_type t,
    pg_namespace n
  WHERE ((t.typname = 'geography'::name) AND (a.attisdropped = false) AND (a.atttypid = t.oid) AND (a.attrelid = c.oid) AND (c.relnamespace = n.oid) AND (c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));;
CREATE OR REPLACE VIEW public.geometry_columns AS  SELECT (current_database())::character varying(256) AS f_table_catalog,
    n.nspname AS f_table_schema,
    c.relname AS f_table_name,
    a.attname AS f_geometry_column,
    COALESCE(postgis_typmod_dims(a.atttypmod), 2) AS coord_dimension,
    COALESCE(NULLIF(postgis_typmod_srid(a.atttypmod), 0), 0) AS srid,
    (replace(replace(COALESCE(NULLIF(upper(postgis_typmod_type(a.atttypmod)), 'GEOMETRY'::text), 'GEOMETRY'::text), 'ZM'::text, ''::text), 'Z'::text, ''::text))::character varying(30) AS type
   FROM (((pg_class c
     JOIN pg_attribute a ON (((a.attrelid = c.oid) AND (NOT a.attisdropped))))
     JOIN pg_namespace n ON ((c.relnamespace = n.oid)))
     JOIN pg_type t ON ((a.atttypid = t.oid)))
  WHERE ((c.relkind = ANY (ARRAY['r'::"char", 'v'::"char", 'm'::"char", 'f'::"char", 'p'::"char"])) AND (NOT (c.relname = 'raster_columns'::name)) AND (t.typname = 'geometry'::name) AND (NOT pg_is_other_temp_schema(c.relnamespace)) AND has_table_privilege(c.oid, 'SELECT'::text));;
CREATE OR REPLACE VIEW public.v_wi_categories_domain AS  WITH RECURSIVE up AS (
         SELECT wi_categories.id,
            wi_categories.org_id,
            wi_categories.parent_id,
            wi_categories.level,
            wi_categories.id AS domain_id
           FROM wi_categories
          WHERE (wi_categories.level = 1)
        UNION ALL
         SELECT c.id,
            c.org_id,
            c.parent_id,
            c.level,
            p.domain_id
           FROM (wi_categories c
             JOIN up p ON ((p.id = c.parent_id)))
        )
 SELECT id,
    org_id,
    parent_id,
    level,
    domain_id
   FROM up;;
CREATE OR REPLACE VIEW public.vw_workflow_instance_progress AS  SELECT wi.id AS instance_id,
    wi.project_id,
    wi.status AS workflow_status,
    count(DISTINCT ws.id) AS total_steps,
    count(DISTINCT wt.id) AS total_tasks,
    sum(
        CASE
            WHEN (ws.status = 'done'::wf_step_status) THEN 1
            ELSE 0
        END) AS steps_done,
    sum(
        CASE
            WHEN (wt.status = 'done'::wf_task_status) THEN 1
            ELSE 0
        END) AS tasks_done
   FROM ((workflow_instances wi
     LEFT JOIN workflow_instance_steps ws ON ((ws.instance_id = wi.id)))
     LEFT JOIN workflow_instance_tasks wt ON ((wt.step_instance_id = ws.id)))
  GROUP BY wi.id, wi.project_id, wi.status;;
CREATE OR REPLACE VIEW public.vw_workflow_template_overview AS  SELECT wt.id AS workflow_template_id,
    wt.name,
    wt.version,
    wt.status,
    count(DISTINCT st.id) AS total_steps,
    count(tt.id) AS total_tasks,
    count(DISTINCT tr.id) AS total_transitions
   FROM (((workflow_templates wt
     LEFT JOIN workflow_step_templates st ON ((st.workflow_template_id = wt.id)))
     LEFT JOIN workflow_task_templates tt ON ((tt.step_template_id = st.id)))
     LEFT JOIN workflow_transitions tr ON ((tr.workflow_template_id = wt.id)))
  GROUP BY wt.id, wt.name, wt.version, wt.status;;

-- Materialized Views
CREATE MATERIALIZED VIEW public.mv_crm_template_suggestions AS  SELECT b.org_id,
    b.work_item_type,
    b.category_id,
    b.subcategory_id,
        CASE
            WHEN (b.subcategory_id IS NOT NULL) THEN 3
            WHEN (b.category_id IS NOT NULL) THEN 2
            ELSE 1
        END AS specificity,
    t.id AS workflow_template_id,
    t.defaults_json,
    t.status AS template_status,
    GREATEST(COALESCE(b.updated_at, '1970-01-01 08:00:00+08'::timestamp with time zone), COALESCE(t.updated_at, '1970-01-01 08:00:00+08'::timestamp with time zone)) AS updated_at
   FROM (workflow_bindings b
     JOIN workflow_templates t ON ((t.id = b.workflow_template_id)))
  WHERE ((b.is_active = true) AND (t.status = ANY (ARRAY['active'::wf_status, 'published'::wf_status])));;

-- Constraints
ALTER TABLE estimating.boq_items ADD FOREIGN KEY (estimate_version_id) REFERENCES estimating.estimate_versions(id) ON DELETE CASCADE;
ALTER TABLE estimating.boq_items ADD FOREIGN KEY (parent_id) REFERENCES estimating.boq_items(id) ON DELETE CASCADE;
ALTER TABLE estimating.boq_items ADD PRIMARY KEY (id);
ALTER TABLE estimating.boq_items ADD FOREIGN KEY (unit_id) REFERENCES price_center.units(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_audits ADD FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_audits ADD FOREIGN KEY (estimate_id) REFERENCES estimating.estimates(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimate_audits ADD FOREIGN KEY (estimate_version_id) REFERENCES estimating.estimate_versions(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_audits ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimate_preset_audits ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimate_preset_audits ADD FOREIGN KEY (preset_id) REFERENCES estimating.estimate_presets(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimate_preset_bindings ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimate_preset_bindings ADD FOREIGN KEY (preset_id) REFERENCES estimating.estimate_presets(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimate_presets ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimate_presets ADD CHECK (((scope)::text = ANY ((ARRAY['Org'::character varying, 'Project'::character varying, 'Package'::character varying])::text[])));
ALTER TABLE estimating.estimate_totals ADD FOREIGN KEY (estimate_version_id) REFERENCES estimating.estimate_versions(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimate_totals ADD PRIMARY KEY (estimate_version_id);
ALTER TABLE estimating.estimate_versions ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_versions ADD FOREIGN KEY (estimate_id) REFERENCES estimating.estimates(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimate_versions ADD UNIQUE (estimate_id, version_no);
ALTER TABLE estimating.estimate_versions ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimate_versions ADD FOREIGN KEY (price_list_id) REFERENCES price_center.price_lists(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_versions ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimate_versions ADD CHECK ((version_no > 0));
ALTER TABLE estimating.estimates ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimates ADD FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimates ADD FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL;
ALTER TABLE estimating.estimates ADD PRIMARY KEY (id);
ALTER TABLE estimating.estimates ADD UNIQUE (project_id, code);
ALTER TABLE estimating.estimates ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE estimating.estimates ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE log.audit_logs ADD PRIMARY KEY (id);
ALTER TABLE log.contracts ADD PRIMARY KEY (id);
ALTER TABLE price_center.effective_price_lists ADD PRIMARY KEY (id);
ALTER TABLE price_center.effective_price_lists ADD CHECK ((status = ANY (ARRAY['draft'::text, 'active'::text, 'inactive'::text, 'expired'::text])));
ALTER TABLE price_center.labor_price_list_items ADD FOREIGN KEY (created_by_user_id) REFERENCES users(id);
ALTER TABLE price_center.labor_price_list_items ADD FOREIGN KEY (labor_price_list_id) REFERENCES price_center.labor_price_lists(id) ON DELETE CASCADE;
ALTER TABLE price_center.labor_price_list_items ADD FOREIGN KEY (unit_id) REFERENCES price_center.units(id);
ALTER TABLE price_center.labor_price_list_items ADD FOREIGN KEY (updated_by_user_id) REFERENCES users(id);
ALTER TABLE price_center.labor_price_list_items ADD PRIMARY KEY (id);
ALTER TABLE price_center.labor_price_lists ADD FOREIGN KEY (created_by_user_id) REFERENCES users(id);
ALTER TABLE price_center.labor_price_lists ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE price_center.labor_price_lists ADD FOREIGN KEY (project_id) REFERENCES projects(id);
ALTER TABLE price_center.labor_price_lists ADD FOREIGN KEY (updated_by_user_id) REFERENCES users(id);
ALTER TABLE price_center.labor_price_lists ADD PRIMARY KEY (id);
ALTER TABLE price_center.material_categories ADD UNIQUE (code);
ALTER TABLE price_center.material_categories ADD FOREIGN KEY (parent_id) REFERENCES price_center.material_categories(id) ON DELETE SET NULL;
ALTER TABLE price_center.material_categories ADD PRIMARY KEY (id);
ALTER TABLE price_center.materials ADD PRIMARY KEY (id);
ALTER TABLE price_center.materials ADD CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])));
ALTER TABLE price_center.outbox_events ADD PRIMARY KEY (id);
ALTER TABLE price_center.outbox_events ADD CHECK ((schema_source = ANY (ARRAY['price_center'::text, 'estimating'::text])));
ALTER TABLE price_center.outbox_events ADD CHECK ((status = ANY (ARRAY['pending'::text, 'published'::text, 'failed'::text])));
ALTER TABLE price_center.price_list_items ADD PRIMARY KEY (id);
ALTER TABLE price_center.price_list_items ADD FOREIGN KEY (price_list_id) REFERENCES price_center.price_lists(id) ON DELETE CASCADE;
ALTER TABLE price_center.price_list_items ADD UNIQUE (price_list_id, material_id);
ALTER TABLE price_center.price_list_items ADD FOREIGN KEY (unit_id) REFERENCES price_center.units(id);
ALTER TABLE price_center.price_lists ADD FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE price_center.price_lists ADD UNIQUE (code);
ALTER TABLE price_center.price_lists ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE price_center.price_lists ADD PRIMARY KEY (id);
ALTER TABLE price_center.supplier_quote_items ADD PRIMARY KEY (id);
ALTER TABLE price_center.supplier_quote_items ADD UNIQUE (supplier_quote_id, material_id);
ALTER TABLE price_center.supplier_quote_items ADD FOREIGN KEY (unit_id) REFERENCES price_center.units(id);
ALTER TABLE price_center.supplier_quotes ADD FOREIGN KEY (material_id) REFERENCES price_center.materials(id);
ALTER TABLE price_center.supplier_quotes ADD PRIMARY KEY (id);
ALTER TABLE price_center.supplier_quotes ADD CHECK ((status = ANY (ARRAY['draft'::text, 'effective'::text, 'expired'::text, 'cancelled'::text])));
ALTER TABLE price_center.supplier_quotes ADD FOREIGN KEY (supplier_id) REFERENCES price_center.suppliers(id) ON DELETE CASCADE;
ALTER TABLE price_center.suppliers ADD PRIMARY KEY (id);
ALTER TABLE price_center.suppliers ADD CHECK (((rating >= 1) AND (rating <= 5)));
ALTER TABLE price_center.suppliers ADD CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text])));
ALTER TABLE price_center.suppliers ADD UNIQUE (supplier_code);
ALTER TABLE price_center.unit_conversions ADD FOREIGN KEY (from_unit_id) REFERENCES price_center.units(id) ON DELETE CASCADE;
ALTER TABLE price_center.unit_conversions ADD UNIQUE (from_unit_id, to_unit_id);
ALTER TABLE price_center.unit_conversions ADD PRIMARY KEY (id);
ALTER TABLE price_center.unit_conversions ADD FOREIGN KEY (to_unit_id) REFERENCES price_center.units(id) ON DELETE CASCADE;
ALTER TABLE price_center.units ADD FOREIGN KEY (base_unit_id) REFERENCES price_center.units(id) ON DELETE SET NULL;
ALTER TABLE price_center.units ADD UNIQUE (code);
ALTER TABLE price_center.units ADD CHECK (((decimals >= 0) AND (decimals <= 6)));
ALTER TABLE price_center.units ADD PRIMARY KEY (id);
ALTER TABLE public.approval_requests ADD FOREIGN KEY (approver_id) REFERENCES users(id);
ALTER TABLE public.approval_requests ADD PRIMARY KEY (id);
ALTER TABLE public.approval_requests ADD FOREIGN KEY (requested_by) REFERENCES users(id);
ALTER TABLE public.approval_requests ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.audit_logs ADD PRIMARY KEY (id);
ALTER TABLE public.configs ADD PRIMARY KEY (id);
ALTER TABLE public.configs ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE public.configs ADD UNIQUE (org_id, key);
ALTER TABLE public.contract_types ADD PRIMARY KEY (id);
ALTER TABLE public.contracts ADD PRIMARY KEY (id);
ALTER TABLE public.contracts ADD FOREIGN KEY (contract_type_id) REFERENCES contract_types(id) ON DELETE RESTRICT;
ALTER TABLE public.contracts ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.contracts ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.contracts ADD FOREIGN KEY (workflow_id) REFERENCES workflows(id);
ALTER TABLE public.departments ADD PRIMARY KEY (id);
ALTER TABLE public.departments ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE public.document_comment_reactions ADD FOREIGN KEY (comment_id) REFERENCES document_comments(id) ON DELETE CASCADE;
ALTER TABLE public.document_comment_reactions ADD PRIMARY KEY (comment_id, user_id, emoji);
ALTER TABLE public.document_comments ADD FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;
ALTER TABLE public.document_comments ADD FOREIGN KEY (parent_id) REFERENCES document_comments(id) ON DELETE CASCADE;
ALTER TABLE public.document_comments ADD PRIMARY KEY (id);
ALTER TABLE public.document_comments ADD FOREIGN KEY (version_id) REFERENCES document_versions(id);
ALTER TABLE public.document_types ADD UNIQUE (code);
ALTER TABLE public.document_types ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE public.document_types ADD PRIMARY KEY (id);
ALTER TABLE public.document_versions ADD FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE;
ALTER TABLE public.document_versions ADD UNIQUE (document_id, version_no);
ALTER TABLE public.document_versions ADD PRIMARY KEY (id);
ALTER TABLE public.documents ADD CHECK (((size_bytes IS NULL) OR (size_bytes >= 0)));
ALTER TABLE public.documents ADD PRIMARY KEY (id);
ALTER TABLE public.documents ADD FOREIGN KEY (type_id) REFERENCES document_types(id) ON DELETE RESTRICT;
ALTER TABLE public.documents ADD FOREIGN KEY (owner_id) REFERENCES users(id);
ALTER TABLE public.documents ADD FOREIGN KEY (package_id) REFERENCES packages(id);
ALTER TABLE public.documents ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.documents ADD FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.idempotency_keys ADD UNIQUE (key);
ALTER TABLE public.idempotency_keys ADD PRIMARY KEY (id);
ALTER TABLE public.notifications ADD PRIMARY KEY (id);
ALTER TABLE public.organizations ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.organizations ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.organizations ADD UNIQUE (code);
ALTER TABLE public.organizations ADD UNIQUE (name);
ALTER TABLE public.organizations ADD PRIMARY KEY (id);
ALTER TABLE public.outbox_events ADD PRIMARY KEY (id);
ALTER TABLE public.packages ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.packages ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.packages ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.packages ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.packages ADD FOREIGN KEY (workflow_id) REFERENCES workflows(id);
ALTER TABLE public.packages ADD PRIMARY KEY (id);
ALTER TABLE public.project_members ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.project_members ADD UNIQUE (user_id, project_id);
ALTER TABLE public.project_members ADD FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.project_members ADD UNIQUE (project_id, user_id);
ALTER TABLE public.projects ADD FOREIGN KEY (accountant_id) REFERENCES users(id);
ALTER TABLE public.projects ADD FOREIGN KEY (engineer_id) REFERENCES users(id);
ALTER TABLE public.projects ADD FOREIGN KEY (project_manager_id) REFERENCES users(id);
ALTER TABLE public.projects ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE public.projects ADD FOREIGN KEY (workflow_id) REFERENCES workflows(id);
ALTER TABLE public.projects ADD PRIMARY KEY (id);
ALTER TABLE public.projects_deleted ADD PRIMARY KEY (id);
ALTER TABLE public.ref_scopes ADD PRIMARY KEY (code);
ALTER TABLE public.refresh_tokens ADD PRIMARY KEY (id);
ALTER TABLE public.refresh_tokens ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.roles ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.roles ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.roles ADD UNIQUE (name);
ALTER TABLE public.roles ADD PRIMARY KEY (id);
ALTER TABLE public.sla_policies ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.sla_policies ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.sla_policies ADD PRIMARY KEY (id);
ALTER TABLE public.spatial_ref_sys ADD PRIMARY KEY (srid);
ALTER TABLE public.spatial_ref_sys ADD CHECK (((srid > 0) AND (srid <= 998999)));
ALTER TABLE public.tags ADD PRIMARY KEY (id);
ALTER TABLE public.task_template_items ADD PRIMARY KEY (id);
ALTER TABLE public.task_template_items ADD FOREIGN KEY (template_id) REFERENCES task_templates(id) ON DELETE CASCADE;
ALTER TABLE public.task_templates ADD PRIMARY KEY (id);
ALTER TABLE public.tasks ADD CHECK (((package_id IS NOT NULL) OR (project_id IS NOT NULL)));
ALTER TABLE public.tasks ADD CHECK (((start_date IS NULL) OR (due_date IS NULL) OR (start_date <= due_date)));
ALTER TABLE public.tasks ADD FOREIGN KEY (assigned_to) REFERENCES users(id);
ALTER TABLE public.tasks ADD FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE;
ALTER TABLE public.tasks ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.tasks ADD PRIMARY KEY (id);
ALTER TABLE public.tickets ADD FOREIGN KEY (assignee_id) REFERENCES users(id);
ALTER TABLE public.tickets ADD PRIMARY KEY (id);
ALTER TABLE public.tickets ADD FOREIGN KEY (reporter_id) REFERENCES users(id);
ALTER TABLE public.tickets ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.timeline_dependencies ADD FOREIGN KEY (depends_on_id) REFERENCES timelines(id) ON DELETE CASCADE;
ALTER TABLE public.timeline_dependencies ADD PRIMARY KEY (id);
ALTER TABLE public.timeline_dependencies ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.timeline_dependencies ADD FOREIGN KEY (timeline_id) REFERENCES timelines(id) ON DELETE CASCADE;
ALTER TABLE public.timelines ADD CHECK ((type = ANY (ARRAY['milestone'::text, 'segment'::text, 'task'::text])));
ALTER TABLE public.timelines ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.timelines ADD FOREIGN KEY (assigned_to) REFERENCES users(id);
ALTER TABLE public.timelines ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.timelines ADD PRIMARY KEY (id);
ALTER TABLE public.user_departments ADD FOREIGN KEY (department_id) REFERENCES departments(id) ON DELETE CASCADE;
ALTER TABLE public.user_departments ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.user_departments ADD UNIQUE (user_id, department_id);
ALTER TABLE public.user_departments ADD FOREIGN KEY (department_id) REFERENCES departments(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_departments ADD PRIMARY KEY (id);
ALTER TABLE public.user_departments ADD FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_devices ADD PRIMARY KEY (id);
ALTER TABLE public.user_devices ADD FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.user_preferences ADD PRIMARY KEY (id);
ALTER TABLE public.user_preferences ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.user_preferences ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
ALTER TABLE public.users ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.users ADD FOREIGN KEY (org_id) REFERENCES organizations(id);
ALTER TABLE public.users ADD FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE RESTRICT;
ALTER TABLE public.users ADD FOREIGN KEY (role_id) REFERENCES roles(id);
ALTER TABLE public.users ADD FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT;
ALTER TABLE public.users ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.users ADD UNIQUE (email);
ALTER TABLE public.users ADD PRIMARY KEY (id);
ALTER TABLE public.users ADD UNIQUE (username);
ALTER TABLE public.webhooks ADD PRIMARY KEY (id);
ALTER TABLE public.webhooks ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.wi_categories ADD CHECK (((level IS NOT NULL) AND (level >= 1)));
ALTER TABLE public.wi_categories ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.wi_categories ADD FOREIGN KEY (parent_id) REFERENCES wi_categories(id) ON DELETE SET NULL;
ALTER TABLE public.wi_categories ADD FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.wi_categories ADD PRIMARY KEY (id);
ALTER TABLE public.wi_sla_pauses ADD FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE public.wi_sla_pauses ADD FOREIGN KEY (policy_id) REFERENCES sla_policies(id) ON DELETE SET NULL;
ALTER TABLE public.wi_sla_pauses ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.wi_sla_pauses ADD PRIMARY KEY (id);
ALTER TABLE public.work_item_attachments ADD PRIMARY KEY (id);
ALTER TABLE public.work_item_attachments ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.work_item_comments ADD PRIMARY KEY (id);
ALTER TABLE public.work_item_comments ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.work_item_idempotency ADD PRIMARY KEY (id);
ALTER TABLE public.work_item_state_history ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.work_item_tags ADD PRIMARY KEY (id);
ALTER TABLE public.work_item_tags ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.work_item_watchers ADD PRIMARY KEY (work_item_id, user_id);
ALTER TABLE public.work_item_watchers ADD FOREIGN KEY (work_item_id) REFERENCES work_items(id) ON DELETE CASCADE;
ALTER TABLE public.work_items ADD CHECK (
CASE
    WHEN ((COALESCE(type, ref_type))::text = ANY ((ARRAY['project'::character varying, 'package'::character varying])::text[])) THEN (project_id IS NOT NULL)
    ELSE true
END);
ALTER TABLE public.work_items ADD CHECK ((priority = ANY (ARRAY['low'::wf_priority, 'medium'::wf_priority, 'high'::wf_priority])));
ALTER TABLE public.work_items ADD CHECK (((type)::text = ANY ((ARRAY['ticket'::character varying, 'request'::character varying, 'approval'::character varying])::text[])));
ALTER TABLE public.work_items ADD PRIMARY KEY (id);
ALTER TABLE public.work_items ADD FOREIGN KEY (ref_scope) REFERENCES ref_scopes(code);
ALTER TABLE public.workflow_bindings ADD FOREIGN KEY (department_id) REFERENCES departments(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.workflow_bindings ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_bindings ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_bindings ADD UNIQUE (workflow_template_id, work_item_type);
ALTER TABLE public.workflow_graph_layouts ADD UNIQUE (workflow_template_id);
ALTER TABLE public.workflow_graph_layouts ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_graph_layouts ADD FOREIGN KEY (step_template_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_graph_layouts ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_graph_layouts ADD UNIQUE (workflow_template_id, step_template_id);
ALTER TABLE public.workflow_instance_journal ADD FOREIGN KEY (from_step_template_id) REFERENCES workflow_step_templates(id);
ALTER TABLE public.workflow_instance_journal ADD FOREIGN KEY (instance_id) REFERENCES workflow_instances(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_instance_journal ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_instance_journal ADD FOREIGN KEY (to_step_template_id) REFERENCES workflow_step_templates(id);
ALTER TABLE public.workflow_instance_journal ADD FOREIGN KEY (transition_id) REFERENCES workflow_transitions(id);
ALTER TABLE public.workflow_instance_steps ADD UNIQUE (instance_id, step_template_id);
ALTER TABLE public.workflow_instance_steps ADD FOREIGN KEY (instance_id) REFERENCES workflow_instances(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_instance_steps ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_instance_steps ADD FOREIGN KEY (step_template_id) REFERENCES workflow_step_templates(id) ON DELETE RESTRICT;
ALTER TABLE public.workflow_instance_tasks ADD UNIQUE (step_instance_id, task_template_id);
ALTER TABLE public.workflow_instance_tasks ADD FOREIGN KEY (step_instance_id) REFERENCES workflow_instance_steps(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_instance_tasks ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_instance_tasks ADD FOREIGN KEY (task_template_id) REFERENCES workflow_task_templates(id) ON DELETE RESTRICT;
ALTER TABLE public.workflow_instances ADD UNIQUE (project_id, workflow_template_id);
ALTER TABLE public.workflow_instances ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_instances ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_instances ADD FOREIGN KEY (owner_id) REFERENCES users(id);
ALTER TABLE public.workflow_instances ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON DELETE RESTRICT;
ALTER TABLE public.workflow_project_bindings ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_project_bindings ADD FOREIGN KEY (project_id) REFERENCES projects(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.workflow_project_bindings ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE public.workflow_step_assignments ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_step_assignments ADD CHECK (((role_in_step)::text = ANY ((ARRAY['owner'::character varying, 'executor'::character varying, 'follower'::character varying])::text[])));
ALTER TABLE public.workflow_step_assignments ADD FOREIGN KEY (workflow_step_id) REFERENCES workflow_steps(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_step_task_templates ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_step_task_templates ADD FOREIGN KEY (template_id) REFERENCES task_templates(id);
ALTER TABLE public.workflow_step_task_templates ADD FOREIGN KEY (workflow_step_id) REFERENCES workflow_steps(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_step_task_templates ADD UNIQUE (workflow_step_id, template_id);
ALTER TABLE public.workflow_step_templates ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_step_templates ADD FOREIGN KEY (role_id) REFERENCES roles(id);
ALTER TABLE public.workflow_step_templates ADD UNIQUE (workflow_template_id, name);
ALTER TABLE public.workflow_step_templates ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_steps ADD FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_steps ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_task_templates ADD FOREIGN KEY (assignee_role_id) REFERENCES roles(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE public.workflow_task_templates ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_task_templates ADD FOREIGN KEY (step_template_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_task_templates ADD UNIQUE (step_template_id, name);
ALTER TABLE public.workflow_template_edges ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_template_nodes ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_templates ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_templates ADD UNIQUE (name, version);
ALTER TABLE public.workflow_transitions ADD CHECK ((from_step_template_id <> to_step_template_id));
ALTER TABLE public.workflow_transitions ADD FOREIGN KEY (from_step_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_transitions ADD FOREIGN KEY (from_step_template_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_transitions ADD PRIMARY KEY (id);
ALTER TABLE public.workflow_transitions ADD FOREIGN KEY (to_step_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_transitions ADD FOREIGN KEY (to_step_template_id) REFERENCES workflow_step_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflow_transitions ADD FOREIGN KEY (workflow_template_id) REFERENCES workflow_templates(id) ON DELETE CASCADE;
ALTER TABLE public.workflows ADD PRIMARY KEY (id);
ALTER TABLE topology.layer ADD PRIMARY KEY (topology_id, layer_id);
ALTER TABLE topology.layer ADD UNIQUE (schema_name, table_name, feature_column);
ALTER TABLE topology.layer ADD FOREIGN KEY (topology_id) REFERENCES topology(id);
ALTER TABLE topology.topology ADD UNIQUE (name);
ALTER TABLE topology.topology ADD PRIMARY KEY (id);
ALTER TABLE warehouse.inventory_balances ADD PRIMARY KEY (id);
ALTER TABLE warehouse.inventory_balances ADD UNIQUE (org_id, project_id, warehouse_id, material_id);
ALTER TABLE warehouse.inventory_balances ADD UNIQUE (org_id, project_id, warehouse_id, material_id);
ALTER TABLE warehouse.issue_headers ADD PRIMARY KEY (id);
ALTER TABLE warehouse.issue_lines ADD PRIMARY KEY (id);
ALTER TABLE warehouse.locations ADD PRIMARY KEY (id);
ALTER TABLE warehouse.mr_headers ADD PRIMARY KEY (id);
ALTER TABLE warehouse.mr_lines ADD PRIMARY KEY (id);
ALTER TABLE warehouse.pallet_items ADD PRIMARY KEY (id);
ALTER TABLE warehouse.pallet_items ADD UNIQUE (pallet_id, material_id);
ALTER TABLE warehouse.pallet_movements ADD PRIMARY KEY (id);
ALTER TABLE warehouse.pallets ADD PRIMARY KEY (id);
ALTER TABLE warehouse.receipt_headers ADD PRIMARY KEY (id);
ALTER TABLE warehouse.receipt_lines ADD PRIMARY KEY (id);
ALTER TABLE warehouse.stocktake_headers ADD PRIMARY KEY (id);
ALTER TABLE warehouse.stocktake_lines ADD PRIMARY KEY (id);
ALTER TABLE warehouse.stocktake_lines ADD FOREIGN KEY (stocktake_id) REFERENCES warehouse.stocktake_headers(id) ON DELETE CASCADE;
ALTER TABLE warehouse.warehouses ADD PRIMARY KEY (id);

-- Indexes
CREATE UNIQUE INDEX boq_items_pkey ON estimating.boq_items USING btree (id);
CREATE UNIQUE INDEX estimate_audits_pkey ON estimating.estimate_audits USING btree (id);
CREATE UNIQUE INDEX estimate_preset_audits_pkey ON estimating.estimate_preset_audits USING btree (id);
CREATE INDEX estimate_preset_audits_preset_id_created_at_idx ON estimating.estimate_preset_audits USING btree (preset_id, created_at DESC);
CREATE UNIQUE INDEX estimate_preset_bindings_pkey ON estimating.estimate_preset_bindings USING btree (id);
CREATE INDEX estimate_preset_bindings_project_id_package_id_idx ON estimating.estimate_preset_bindings USING btree (project_id, package_id);
CREATE INDEX estimate_presets_is_active_idx ON estimating.estimate_presets USING btree (is_active);
CREATE UNIQUE INDEX estimate_presets_pkey ON estimating.estimate_presets USING btree (id);
CREATE INDEX estimate_presets_to_tsvector_idx ON estimating.estimate_presets USING gin (to_tsvector('simple'::regconfig, (name)::text));
CREATE UNIQUE INDEX estimate_totals_pkey ON estimating.estimate_totals USING btree (estimate_version_id);
CREATE UNIQUE INDEX estimate_versions_estimate_id_version_no_key ON estimating.estimate_versions USING btree (estimate_id, version_no);
CREATE UNIQUE INDEX estimate_versions_pkey ON estimating.estimate_versions USING btree (id);
CREATE UNIQUE INDEX estimates_pkey ON estimating.estimates USING btree (id);
CREATE UNIQUE INDEX estimates_project_id_code_key ON estimating.estimates USING btree (project_id, code);
CREATE INDEX idx_boq_parent ON estimating.boq_items USING btree (parent_id);
CREATE INDEX idx_boq_sort ON estimating.boq_items USING btree (estimate_version_id, sort_order);
CREATE INDEX idx_boq_version ON estimating.boq_items USING btree (estimate_version_id);
CREATE INDEX idx_estimate_audits_est ON estimating.estimate_audits USING btree (estimate_id, created_at DESC);
CREATE INDEX idx_estimate_audits_ver ON estimating.estimate_audits USING btree (estimate_version_id);
CREATE INDEX idx_estimate_totals_updated ON estimating.estimate_totals USING btree (updated_at DESC);
CREATE INDEX idx_estimate_versions_estimate ON estimating.estimate_versions USING btree (estimate_id);
CREATE INDEX idx_estimate_versions_final ON estimating.estimate_versions USING btree (is_finalized);
CREATE INDEX idx_estimate_versions_price ON estimating.estimate_versions USING btree (price_list_id);
CREATE INDEX idx_estimates_name ON estimating.estimates USING btree (name);
CREATE INDEX idx_estimates_owner ON estimating.estimates USING btree (owner_id);
CREATE INDEX idx_estimates_package ON estimating.estimates USING btree (package_id);
CREATE INDEX idx_estimates_project ON estimating.estimates USING btree (project_id);
CREATE INDEX idx_estimates_status ON estimating.estimates USING btree (status);
CREATE INDEX idx_estimates_updated ON estimating.estimates USING btree (updated_at DESC);
CREATE UNIQUE INDEX audit_logs_pkey ON log.audit_logs USING btree (id);
CREATE UNIQUE INDEX contracts_pkey ON log.contracts USING btree (id);
CREATE INDEX idx_audit_logs_record_type ON log.audit_logs USING btree (record_type);
CREATE INDEX idx_audit_logs_record_type_record_id ON log.audit_logs USING btree (record_type, record_id);
CREATE INDEX idx_audit_logs_user_id_timestamp ON log.audit_logs USING btree (user_id, "timestamp");
CREATE UNIQUE INDEX effective_price_lists_pkey ON price_center.effective_price_lists USING btree (id);
CREATE INDEX idx_labor_price_list_items_job_code ON price_center.labor_price_list_items USING btree (job_code);
CREATE INDEX idx_labor_price_list_items_list ON price_center.labor_price_list_items USING btree (labor_price_list_id);
CREATE INDEX idx_labor_price_lists_effective_range ON price_center.labor_price_lists USING btree (effective_from, effective_to);
CREATE INDEX idx_labor_price_lists_org_project ON price_center.labor_price_lists USING btree (org_id, project_id);
CREATE INDEX idx_labor_price_lists_status ON price_center.labor_price_lists USING btree (status);
CREATE INDEX idx_matcat_parent ON price_center.material_categories USING btree (parent_id);
CREATE INDEX idx_pl_items_list ON price_center.price_list_items USING btree (price_list_id);
CREATE INDEX idx_pl_items_material ON price_center.price_list_items USING btree (material_id);
CREATE INDEX idx_pl_name ON price_center.price_lists USING btree (name);
CREATE INDEX idx_price_lists_status ON price_center.price_lists USING btree (status);
CREATE INDEX idx_price_lists_valid ON price_center.price_lists USING btree (valid_from, valid_to);
CREATE INDEX idx_sq_items_material ON price_center.supplier_quote_items USING btree (material_id);
CREATE INDEX idx_sq_items_quote ON price_center.supplier_quote_items USING btree (supplier_quote_id);
CREATE INDEX idx_unit_conversions_from ON price_center.unit_conversions USING btree (from_unit_id);
CREATE INDEX idx_unit_conversions_to ON price_center.unit_conversions USING btree (to_unit_id);
CREATE INDEX idx_units_active ON price_center.units USING btree (is_active);
CREATE INDEX idx_units_name ON price_center.units USING btree (name);
CREATE INDEX ix_effective_price_lists_effective_range ON price_center.effective_price_lists USING btree (effective_from, effective_to);
CREATE INDEX ix_effective_price_lists_material ON price_center.effective_price_lists USING btree (material_id);
CREATE INDEX ix_effective_price_lists_status ON price_center.effective_price_lists USING btree (status);
CREATE INDEX ix_effective_price_lists_supplier ON price_center.effective_price_lists USING btree (supplier_id);
CREATE INDEX ix_effective_price_lists_updated_at ON price_center.effective_price_lists USING btree (updated_at DESC);
CREATE INDEX ix_materials_updated_at ON price_center.materials USING btree (updated_at DESC);
CREATE INDEX ix_outbox_payload_gin ON price_center.outbox_events USING gin (payload);
CREATE INDEX ix_outbox_producer_status ON price_center.outbox_events USING btree (producer, status);
CREATE INDEX ix_outbox_status_time ON price_center.outbox_events USING btree (status, occurred_at);
CREATE INDEX ix_pl_status_from_to ON price_center.price_lists USING btree (status, valid_from DESC, valid_to);
CREATE INDEX ix_pli_material ON price_center.price_list_items USING btree (material_id);
CREATE INDEX ix_sqi_material ON price_center.supplier_quote_items USING btree (material_id);
CREATE INDEX ix_supplier_quotes_item_code ON price_center.supplier_quotes USING btree (item_code);
CREATE INDEX ix_supplier_quotes_material ON price_center.supplier_quotes USING btree (material_id);
CREATE INDEX ix_supplier_quotes_updated_at ON price_center.supplier_quotes USING btree (updated_at DESC);
CREATE INDEX ix_supplier_quotes_validity ON price_center.supplier_quotes USING btree (status, valid_from, valid_to);
CREATE INDEX ix_suppliers_supplier_code ON price_center.suppliers USING btree (supplier_code);
CREATE INDEX ix_suppliers_updated_at ON price_center.suppliers USING btree (updated_at DESC);
CREATE UNIQUE INDEX material_categories_code_key ON price_center.material_categories USING btree (code);
CREATE UNIQUE INDEX material_categories_pkey ON price_center.material_categories USING btree (id);
CREATE UNIQUE INDEX materials_pkey ON price_center.materials USING btree (id);
CREATE UNIQUE INDEX outbox_events_pkey ON price_center.outbox_events USING btree (id);
CREATE UNIQUE INDEX pk_labor_price_list_items ON price_center.labor_price_list_items USING btree (id);
CREATE UNIQUE INDEX pk_labor_price_lists ON price_center.labor_price_lists USING btree (id);
CREATE UNIQUE INDEX price_list_items_pkey ON price_center.price_list_items USING btree (id);
CREATE UNIQUE INDEX price_list_items_price_list_id_material_id_key ON price_center.price_list_items USING btree (price_list_id, material_id);
CREATE UNIQUE INDEX price_lists_code_key ON price_center.price_lists USING btree (code);
CREATE UNIQUE INDEX price_lists_pkey ON price_center.price_lists USING btree (id);
CREATE UNIQUE INDEX supplier_quote_items_pkey ON price_center.supplier_quote_items USING btree (id);
CREATE UNIQUE INDEX supplier_quote_items_supplier_quote_id_material_id_key ON price_center.supplier_quote_items USING btree (supplier_quote_id, material_id);
CREATE UNIQUE INDEX supplier_quotes_pkey ON price_center.supplier_quotes USING btree (id);
CREATE UNIQUE INDEX suppliers_pkey ON price_center.suppliers USING btree (id);
CREATE UNIQUE INDEX suppliers_supplier_code_key ON price_center.suppliers USING btree (supplier_code);
CREATE UNIQUE INDEX unit_conversions_from_unit_id_to_unit_id_key ON price_center.unit_conversions USING btree (from_unit_id, to_unit_id);
CREATE UNIQUE INDEX unit_conversions_pkey ON price_center.unit_conversions USING btree (id);
CREATE UNIQUE INDEX units_code_key ON price_center.units USING btree (code);
CREATE UNIQUE INDEX units_pkey ON price_center.units USING btree (id);
CREATE UNIQUE INDEX ux_effective_price_lists_code ON price_center.effective_price_lists USING btree (lower(price_list_code));
CREATE UNIQUE INDEX ux_materials_item_code ON price_center.materials USING btree (lower(item_code));
CREATE UNIQUE INDEX ux_supplier_quotes_supplier_code ON price_center.supplier_quotes USING btree (supplier_id, lower(quote_code));
CREATE UNIQUE INDEX approval_requests_pkey ON public.approval_requests USING btree (id);
CREATE UNIQUE INDEX audit_logs_pkey ON public.audit_logs USING btree (id);
CREATE UNIQUE INDEX configs_pkey ON public.configs USING btree (id);
CREATE UNIQUE INDEX contract_types_pkey ON public.contract_types USING btree (id);
CREATE UNIQUE INDEX contracts_pkey ON public.contracts USING btree (id);
CREATE UNIQUE INDEX departments_pkey ON public.departments USING btree (id);
CREATE UNIQUE INDEX document_comment_reactions_pkey ON public.document_comment_reactions USING btree (comment_id, user_id, emoji);
CREATE UNIQUE INDEX document_comments_pkey ON public.document_comments USING btree (id);
CREATE UNIQUE INDEX document_types_code_key ON public.document_types USING btree (code);
CREATE UNIQUE INDEX document_types_pkey ON public.document_types USING btree (id);
CREATE UNIQUE INDEX document_versions_document_id_version_no_key ON public.document_versions USING btree (document_id, version_no);
CREATE UNIQUE INDEX document_versions_pkey ON public.document_versions USING btree (id);
CREATE UNIQUE INDEX documents_pkey ON public.documents USING btree (id);
CREATE INDEX gin_configs_value ON public.configs USING gin (value);
CREATE INDEX gin_documents_permissions ON public.documents USING gin (permissions jsonb_path_ops);
CREATE INDEX gin_documents_perms ON public.documents USING gin (permissions);
CREATE INDEX gin_outbox_payload ON public.outbox_events USING gin (payload);
CREATE INDEX gin_roles_permissions ON public.roles USING gin (permissions);
CREATE INDEX gin_sla_policies_apply_rules ON public.sla_policies USING gin (apply_rules);
CREATE INDEX gin_wi_categories_name_norm ON public.wi_categories USING gin (name_norm gin_trgm_ops);
CREATE INDEX gin_work_items_data ON public.work_items USING gin (data);
CREATE UNIQUE INDEX idempotency_keys_key_key ON public.idempotency_keys USING btree (key);
CREATE UNIQUE INDEX idempotency_keys_pkey ON public.idempotency_keys USING btree (id);
CREATE INDEX idx_approval_requests_wi ON public.approval_requests USING btree (work_item_id);
CREATE INDEX idx_audit_logs_record_type ON public.audit_logs USING btree (record_type);
CREATE INDEX idx_audit_logs_record_type_record_id ON public.audit_logs USING btree (record_type, record_id);
CREATE INDEX idx_audit_logs_user_id_timestamp ON public.audit_logs USING btree (user_id, "timestamp");
CREATE INDEX idx_audit_record ON public.audit_logs USING btree (record_type, record_id, "timestamp" DESC);
CREATE INDEX idx_configs_scope_external ON public.configs USING btree (scope, external_key);
CREATE INDEX idx_configs_scope_key ON public.configs USING btree (scope, key);
CREATE INDEX idx_contracts_project_id ON public.contracts USING btree (project_id);
CREATE INDEX idx_departments_code ON public.departments USING btree (code);
CREATE INDEX idx_departments_org_id ON public.departments USING btree (org_id);
CREATE INDEX idx_doccm_dept ON public.document_comments USING btree (dept_code);
CREATE INDEX idx_doccm_doc ON public.document_comments USING btree (document_id, created_at DESC);
CREATE INDEX idx_doccm_doc_ver ON public.document_comments USING btree (document_id, version_id);
CREATE INDEX idx_doccm_parent ON public.document_comments USING btree (parent_id);
CREATE INDEX idx_document_types_active_order ON public.document_types USING btree (is_active, sort_order);
CREATE INDEX idx_document_types_scope_org ON public.document_types USING btree (scope, org_id);
CREATE INDEX idx_documents_pkg ON public.documents USING btree (package_id);
CREATE INDEX idx_documents_project_id ON public.documents USING btree (project_id);
CREATE INDEX idx_documents_type ON public.documents USING btree (doc_type);
CREATE INDEX idx_docver_doc ON public.document_versions USING btree (document_id, version_no DESC);
CREATE INDEX idx_organizations_name ON public.organizations USING btree (name);
CREATE INDEX idx_outbox_agg ON public.outbox_events USING btree (aggregate, aggregate_id);
CREATE INDEX idx_outbox_aggregate ON public.outbox_events USING btree (aggregate, aggregate_id);
CREATE INDEX idx_outbox_pending ON public.outbox_events USING btree (id) WHERE (published_at IS NULL);
CREATE INDEX idx_outbox_retry ON public.outbox_events USING btree (next_retry_at) WHERE (published_at IS NULL);
CREATE INDEX idx_outbox_type_time ON public.outbox_events USING btree (event_type, occurred_at);
CREATE INDEX idx_outbox_unprocessed ON public.outbox_events USING btree (occurred_at) WHERE (processed_at IS NULL);
CREATE INDEX idx_packages_project_id ON public.packages USING btree (project_id);
CREATE INDEX idx_packages_status ON public.packages USING btree (status);
CREATE INDEX idx_project_members_active ON public.project_members USING btree (is_active);
CREATE INDEX idx_project_members_proj_user ON public.project_members USING btree (project_id, user_id);
CREATE INDEX idx_projects_is_archived ON public.projects USING btree (is_archived);
CREATE INDEX idx_projects_org_id ON public.projects USING btree (org_id);
CREATE INDEX idx_projects_status ON public.projects USING btree (status);
CREATE INDEX idx_projects_type ON public.projects USING btree (type);
CREATE INDEX idx_rt_expires ON public.refresh_tokens USING btree (expires_at);
CREATE INDEX idx_rt_user ON public.refresh_tokens USING btree (user_id);
CREATE INDEX idx_sla_policies_org_active ON public.sla_policies USING btree (org_id, is_active);
CREATE INDEX idx_tags_domain ON public.tags USING btree (domain);
CREATE INDEX idx_tags_name_trgm ON public.tags USING gin (name gin_trgm_ops);
CREATE INDEX idx_tags_org ON public.tags USING btree (org_id);
CREATE INDEX idx_task_templates_active ON public.task_templates USING btree (is_active);
CREATE INDEX idx_task_templates_org ON public.task_templates USING btree (org_id);
CREATE INDEX idx_tasks_assigned_to ON public.tasks USING btree (assigned_to);
CREATE INDEX idx_tasks_due_date ON public.tasks USING btree (due_date);
CREATE INDEX idx_tasks_is_deleted ON public.tasks USING btree (is_deleted);
CREATE INDEX idx_tasks_package_id ON public.tasks USING btree (package_id);
CREATE INDEX idx_tasks_priority ON public.tasks USING btree (priority);
CREATE INDEX idx_tasks_project_id ON public.tasks USING btree (project_id);
CREATE INDEX idx_tasks_status ON public.tasks USING btree (status);
CREATE INDEX idx_tasks_updated_at ON public.tasks USING btree (updated_at);
CREATE INDEX idx_tickets_wi ON public.tickets USING btree (work_item_id);
CREATE INDEX idx_timeline_dependencies_depends_on ON public.timeline_dependencies USING btree (depends_on_id);
CREATE INDEX idx_timeline_dependencies_timeline ON public.timeline_dependencies USING btree (timeline_id);
CREATE INDEX idx_timelines_assigned_to ON public.timelines USING btree (assigned_to);
CREATE INDEX idx_timelines_assignee ON public.timelines USING btree (project_id, assigned_to);
CREATE INDEX idx_timelines_date ON public.timelines USING btree (project_id, COALESCE(start_date, end_date), end_date);
CREATE INDEX idx_timelines_dates ON public.timelines USING btree (start_date, end_date);
CREATE INDEX idx_timelines_priority ON public.timelines USING btree (priority);
CREATE INDEX idx_timelines_project ON public.timelines USING btree (project_id);
CREATE INDEX idx_timelines_project_id ON public.timelines USING btree (project_id);
CREATE INDEX idx_timelines_project_type ON public.timelines USING btree (project_id, type);
CREATE INDEX idx_timelines_status ON public.timelines USING btree (status);
CREATE INDEX idx_timelines_type ON public.timelines USING btree (type);
CREATE INDEX idx_tti_sort ON public.task_template_items USING btree (template_id, sort_order);
CREATE INDEX idx_tti_template ON public.task_template_items USING btree (template_id);
CREATE INDEX idx_user_departments_active ON public.user_departments USING btree (is_active);
CREATE INDEX idx_user_departments_dept ON public.user_departments USING btree (department_id);
CREATE INDEX idx_user_departments_user ON public.user_departments USING btree (user_id);
CREATE INDEX idx_user_devices_user ON public.user_devices USING btree (user_id, is_active);
CREATE INDEX idx_user_preferences_project ON public.user_preferences USING btree (project_id);
CREATE INDEX idx_user_preferences_user ON public.user_preferences USING btree (user_id);
CREATE INDEX idx_users_email ON public.users USING btree (lower((email)::text));
CREATE INDEX idx_users_unaccent_full_name ON public.users USING btree (f_unaccent_immutable((lower((full_name)::text))::character varying));
CREATE INDEX idx_webhooks_event ON public.webhooks USING btree (event);
CREATE INDEX idx_webhooks_project ON public.webhooks USING btree (project_id);
CREATE INDEX idx_wf_instances_project ON public.workflow_instances USING btree (project_id);
CREATE INDEX idx_wf_instances_workitem ON public.workflow_instances USING btree (work_item_id);
CREATE INDEX idx_wf_step_assign_dept ON public.workflow_step_assignments USING btree (department_id);
CREATE INDEX idx_wf_step_assign_step ON public.workflow_step_assignments USING btree (workflow_step_id);
CREATE INDEX idx_wf_step_assign_user ON public.workflow_step_assignments USING btree (user_id);
CREATE INDEX idx_wfgl_wf ON public.workflow_graph_layouts USING btree (workflow_template_id);
CREATE INDEX idx_wfi_project ON public.workflow_instances USING btree (project_id);
CREATE INDEX idx_wfi_status ON public.workflow_instances USING btree (status);
CREATE INDEX idx_wfi_template ON public.workflow_instances USING btree (workflow_template_id);
CREATE INDEX idx_wfij_instance ON public.workflow_instance_journal USING btree (instance_id);
CREATE INDEX idx_wfij_transition ON public.workflow_instance_journal USING btree (transition_id);
CREATE INDEX idx_wfis_deadline ON public.workflow_instance_steps USING btree (deadline);
CREATE INDEX idx_wfis_instance ON public.workflow_instance_steps USING btree (instance_id);
CREATE INDEX idx_wfis_status ON public.workflow_instance_steps USING btree (status);
CREATE INDEX idx_wfit_assignee ON public.workflow_instance_tasks USING btree (assignee_id);
CREATE INDEX idx_wfit_due_date ON public.workflow_instance_tasks USING btree (due_date);
CREATE INDEX idx_wfit_priority ON public.workflow_instance_tasks USING btree (priority);
CREATE INDEX idx_wfit_status ON public.workflow_instance_tasks USING btree (status);
CREATE INDEX idx_wfst_order ON public.workflow_step_templates USING btree (workflow_template_id, "order");
CREATE INDEX idx_wfst_wf ON public.workflow_step_templates USING btree (workflow_template_id);
CREATE INDEX idx_wfst_wf_order ON public.workflow_step_templates USING btree (workflow_template_id, "order");
CREATE INDEX idx_wft_status ON public.workflow_templates USING btree (status);
CREATE INDEX idx_wftr_condition_gin ON public.workflow_transitions USING gin (condition_json);
CREATE INDEX idx_wftr_from ON public.workflow_transitions USING btree (workflow_template_id, from_step_template_id);
CREATE INDEX idx_wftr_loopback ON public.workflow_transitions USING btree (transition_type) WHERE (transition_type = 'loopback'::wf_transition_type);
CREATE INDEX idx_wftrans_from_step_id ON public.workflow_transitions USING btree (from_step_id);
CREATE INDEX idx_wftrans_outcome ON public.workflow_transitions USING btree (outcome);
CREATE INDEX idx_wftrans_policy_type ON public.workflow_transitions USING btree (policy_type);
CREATE INDEX idx_wftrans_to_step_id ON public.workflow_transitions USING btree (to_step_id);
CREATE INDEX idx_wftransitions_workflow ON public.workflow_transitions USING btree (workflow_template_id);
CREATE INDEX idx_wi_assignee ON public.work_items USING btree (assignee_id);
CREATE INDEX idx_wi_attachments_work_item ON public.work_item_attachments USING btree (work_item_id);
CREATE INDEX idx_wi_categories_name_norm ON public.wi_categories USING btree (name_norm);
CREATE INDEX idx_wi_categories_org_active_level_order ON public.wi_categories USING btree (org_id, is_active, level, order_no);
CREATE INDEX idx_wi_categories_org_active_order ON public.wi_categories USING btree (org_id, is_active, order_no);
CREATE INDEX idx_wi_categories_org_default_type ON public.wi_categories USING btree (org_id, default_type);
CREATE INDEX idx_wi_categories_org_template_form ON public.wi_categories USING btree (org_id, template_code, form_key);
CREATE INDEX idx_wi_categories_parent ON public.wi_categories USING btree (parent_id);
CREATE INDEX idx_wi_department ON public.work_items USING btree (department_id);
CREATE INDEX idx_wi_due_at ON public.work_items USING btree (due_at);
CREATE INDEX idx_wi_idem_expires ON public.work_item_idempotency USING btree (expires_at);
CREATE INDEX idx_wi_idem_org_user ON public.work_item_idempotency USING btree (org_id, user_id);
CREATE INDEX idx_wi_not_deleted ON public.work_items USING btree (id) WHERE (is_deleted = false);
CREATE INDEX idx_wi_priority ON public.work_items USING btree (priority);
CREATE INDEX idx_wi_requester ON public.work_items USING btree (requester_id);
CREATE INDEX idx_wi_sla_pauses_open ON public.wi_sla_pauses USING btree (work_item_id) WHERE (ended_at IS NULL);
CREATE INDEX idx_wi_sla_pauses_policy ON public.wi_sla_pauses USING btree (policy_id);
CREATE INDEX idx_wi_sla_pauses_wi_started ON public.wi_sla_pauses USING btree (work_item_id, started_at);
CREATE INDEX idx_wi_sla_status ON public.work_items USING btree (sla_status);
CREATE INDEX idx_wi_status ON public.work_items USING btree (status);
CREATE INDEX idx_wi_tags_work_item ON public.work_item_tags USING btree (work_item_id);
CREATE INDEX idx_wi_type ON public.work_items USING btree (type);
CREATE INDEX idx_wia_wi ON public.work_item_attachments USING btree (work_item_id);
CREATE INDEX idx_wic_wi ON public.work_item_comments USING btree (work_item_id);
CREATE INDEX idx_wishistory_workitem_time ON public.work_item_state_history USING btree (work_item_id, created_at DESC);
CREATE INDEX idx_wit_wi ON public.work_item_tags USING btree (work_item_id);
CREATE INDEX idx_wiw_user ON public.work_item_watchers USING btree (user_id);
CREATE INDEX idx_work_items_binding_id ON public.work_items USING btree (applied_binding_id);
CREATE INDEX idx_work_items_data_gin ON public.work_items USING gin (data);
CREATE INDEX idx_work_items_instance_id ON public.work_items USING btree (workflow_instance_id);
CREATE INDEX idx_work_items_priority ON public.work_items USING btree (priority);
CREATE INDEX idx_work_items_scope ON public.work_items USING btree (ref_scope, ref_id);
CREATE INDEX idx_work_items_template_code ON public.work_items USING btree (workflow_template_code);
CREATE INDEX idx_work_items_template_id ON public.work_items USING btree (workflow_template_id);
CREATE INDEX idx_workflow_steps_assignees ON public.workflow_steps USING gin (assignees);
CREATE INDEX idx_workflow_steps_completion_conditions ON public.workflow_steps USING gin (completion_conditions);
CREATE INDEX idx_workflow_steps_doers ON public.workflow_steps USING gin (doers);
CREATE INDEX idx_workflow_steps_watchers ON public.workflow_steps USING gin (watchers);
CREATE INDEX idx_workflows_scope ON public.workflows USING btree (scope);
CREATE INDEX idx_workitems_project_id ON public.work_items USING btree (project_id);
CREATE INDEX idx_workitems_ref_type ON public.work_items USING btree (ref_type);
CREATE INDEX idx_workitems_title_trgm ON public.work_items USING gin (title gin_trgm_ops);
CREATE INDEX idx_wp_bind_project_time ON public.workflow_project_bindings USING btree (project_id, updated_at DESC);
CREATE INDEX idx_wstt_step ON public.workflow_step_task_templates USING btree (workflow_step_id);
CREATE INDEX idx_wstt_template ON public.workflow_step_task_templates USING btree (template_id);
CREATE INDEX idx_wte_template_extkey_partial ON public.workflow_template_edges USING btree (template_id, external_key) WHERE (external_key IS NOT NULL);
CREATE INDEX idx_wtn_template_extkey_partial ON public.workflow_template_nodes USING btree (template_id, external_key) WHERE (external_key IS NOT NULL);
CREATE INDEX idx_wtt_assignee_role ON public.workflow_task_templates USING btree (step_template_id, assignee_role);
CREATE INDEX idx_wtt_assignee_role_id ON public.workflow_task_templates USING btree (assignee_role_id);
CREATE INDEX idx_wtt_priority ON public.workflow_task_templates USING btree (priority);
CREATE INDEX idx_wtt_step ON public.workflow_task_templates USING btree (step_template_id);
CREATE INDEX idx_wtt_step_order ON public.workflow_task_templates USING btree (step_template_id, "order");
CREATE INDEX ix_document_types_domain_active ON public.document_types USING btree (domain, is_active);
CREATE INDEX ix_document_versions_document_id ON public.document_versions USING btree (document_id);
CREATE INDEX ix_documents_created_at ON public.documents USING btree (created_at DESC);
CREATE INDEX ix_documents_name_unaccent ON public.documents USING btree (immutable_unaccent((name)::text));
CREATE INDEX ix_documents_proj_pkg_type_dep_stat ON public.documents USING btree (project_id, package_id, doc_type, department, status);
CREATE INDEX ix_documents_type_id ON public.documents USING btree (type_id);
CREATE INDEX ix_mv_crm_tpl_suggest_lookup ON public.mv_crm_template_suggestions USING btree (org_id, work_item_type, subcategory_id, category_id, specificity DESC, template_status, updated_at DESC);
CREATE INDEX ix_wfpb_project_status ON public.workflow_project_bindings USING btree (project_id, status);
CREATE INDEX ix_wfpb_template_version ON public.workflow_project_bindings USING btree (workflow_template_id, workflow_template_version);
CREATE UNIQUE INDEX notifications_pkey ON public.notifications USING btree (id);
CREATE UNIQUE INDEX organizations_code_key ON public.organizations USING btree (code);
CREATE UNIQUE INDEX organizations_name_key ON public.organizations USING btree (name);
CREATE UNIQUE INDEX organizations_pkey ON public.organizations USING btree (id);
CREATE UNIQUE INDEX outbox_events_pkey ON public.outbox_events USING btree (id);
CREATE UNIQUE INDEX packages_pkey ON public.packages USING btree (id);
CREATE INDEX project_members_id_idx ON public.project_members USING btree (id);
CREATE UNIQUE INDEX project_members_unique ON public.project_members USING btree (user_id, project_id);
CREATE UNIQUE INDEX projects_delete_pkey ON public.projects_deleted USING btree (id);
CREATE UNIQUE INDEX projects_pkey ON public.projects USING btree (id);
CREATE UNIQUE INDEX ref_scopes_pkey ON public.ref_scopes USING btree (code);
CREATE UNIQUE INDEX refresh_tokens_pkey ON public.refresh_tokens USING btree (id);
CREATE UNIQUE INDEX roles_name_key ON public.roles USING btree (name);
CREATE UNIQUE INDEX roles_pkey ON public.roles USING btree (id);
CREATE UNIQUE INDEX sla_policies_pkey ON public.sla_policies USING btree (id);
CREATE UNIQUE INDEX spatial_ref_sys_pkey ON public.spatial_ref_sys USING btree (srid);
CREATE UNIQUE INDEX tags_pkey ON public.tags USING btree (id);
CREATE UNIQUE INDEX task_template_items_pkey ON public.task_template_items USING btree (id);
CREATE UNIQUE INDEX task_templates_pkey ON public.task_templates USING btree (id);
CREATE UNIQUE INDEX tasks_pkey ON public.tasks USING btree (id);
CREATE UNIQUE INDEX tickets_pkey ON public.tickets USING btree (id);
CREATE UNIQUE INDEX timeline_dependencies_pkey ON public.timeline_dependencies USING btree (id);
CREATE UNIQUE INDEX timelines_pkey ON public.timelines USING btree (id);
CREATE UNIQUE INDEX uix_sla_policies_org_code_alive ON public.sla_policies USING btree (org_id, lower((code)::text)) WHERE (deleted_at IS NULL);
CREATE UNIQUE INDEX uix_wi_categories_org_code_alive ON public.wi_categories USING btree (org_id, lower((code)::text)) WHERE (deleted_at IS NULL);
CREATE UNIQUE INDEX unique_org_key ON public.configs USING btree (org_id, key);
CREATE UNIQUE INDEX uq_idempotency_key ON public.idempotency_keys USING btree (key);
CREATE UNIQUE INDEX uq_project_members ON public.project_members USING btree (project_id, user_id);
CREATE UNIQUE INDEX uq_tags_org_domain_slug ON public.tags USING btree (org_id, domain, lower((slug)::text));
CREATE UNIQUE INDEX uq_user_departments ON public.user_departments USING btree (user_id, department_id) WHERE (is_active = true);
CREATE UNIQUE INDEX uq_user_departments_user_dept ON public.user_departments USING btree (user_id, department_id);
CREATE UNIQUE INDEX uq_wfi_project_template ON public.workflow_instances USING btree (project_id, workflow_template_id);
CREATE UNIQUE INDEX uq_wfinst_project_template ON public.workflow_instances USING btree (project_id, workflow_template_id) WHERE (project_id IS NOT NULL);
CREATE UNIQUE INDEX uq_wfinst_workitem_template ON public.workflow_instances USING btree (work_item_id, workflow_template_id) WHERE (work_item_id IS NOT NULL);
CREATE UNIQUE INDEX uq_wfis_instance_step_template ON public.workflow_instance_steps USING btree (instance_id, step_template_id);
CREATE UNIQUE INDEX uq_wfit_instance_task_template ON public.workflow_instance_tasks USING btree (step_instance_id, task_template_id);
CREATE UNIQUE INDEX uq_wfst_name_in_wf ON public.workflow_step_templates USING btree (workflow_template_id, name);
CREATE UNIQUE INDEX uq_wft_name_version ON public.workflow_templates USING btree (name, version);
CREATE UNIQUE INDEX uq_wftr_from_to ON public.workflow_transitions USING btree (workflow_template_id, from_step_template_id, to_step_template_id);
CREATE UNIQUE INDEX uq_wftr_one_default_per_from ON public.workflow_transitions USING btree (from_step_template_id) WHERE (is_default = true);
CREATE UNIQUE INDEX uq_wi_tag ON public.work_item_tags USING btree (work_item_id, tag);
CREATE UNIQUE INDEX uq_wit_wi_tag ON public.work_item_tags USING btree (work_item_id, tag);
CREATE UNIQUE INDEX uq_wit_workitem_tag ON public.work_item_tags USING btree (work_item_id, tag);
CREATE UNIQUE INDEX uq_wiw_workitem_user ON public.work_item_watchers USING btree (work_item_id, user_id);
CREATE UNIQUE INDEX uq_wte_template_extkey ON public.workflow_template_edges USING btree (template_id, external_key);
CREATE UNIQUE INDEX uq_wtn_template_extkey ON public.workflow_template_nodes USING btree (template_id, external_key);
CREATE UNIQUE INDEX uq_wtt_name_in_step ON public.workflow_task_templates USING btree (step_template_id, name);
CREATE INDEX user_departments_id_idx ON public.user_departments USING btree (id);
CREATE UNIQUE INDEX user_departments_pk ON public.user_departments USING btree (id);
CREATE UNIQUE INDEX user_devices_pkey ON public.user_devices USING btree (id);
CREATE UNIQUE INDEX user_preferences_pkey ON public.user_preferences USING btree (id);
CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);
CREATE UNIQUE INDEX users_pkey ON public.users USING btree (id);
CREATE UNIQUE INDEX users_username_key ON public.users USING btree (username);
CREATE UNIQUE INDEX ux_contract_types_code ON public.contract_types USING btree (code);
CREATE UNIQUE INDEX ux_mv_crm_tpl_suggest_unique ON public.mv_crm_template_suggestions USING btree (org_id, work_item_type, COALESCE(category_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(subcategory_id, '00000000-0000-0000-0000-000000000000'::uuid), workflow_template_id);
CREATE UNIQUE INDEX ux_wfgl_template ON public.workflow_graph_layouts USING btree (workflow_template_id);
CREATE UNIQUE INDEX ux_wfpb_active ON public.workflow_project_bindings USING btree (project_id, workflow_template_id) WHERE ((status)::text = 'active'::text);
CREATE UNIQUE INDEX ux_wi_idem_key ON public.work_item_idempotency USING btree (idem_key);
CREATE UNIQUE INDEX webhooks_pkey ON public.webhooks USING btree (id);
CREATE UNIQUE INDEX wi_categories_pkey ON public.wi_categories USING btree (id);
CREATE UNIQUE INDEX wi_sla_pauses_pkey ON public.wi_sla_pauses USING btree (id);
CREATE UNIQUE INDEX work_item_attachments_pkey ON public.work_item_attachments USING btree (id);
CREATE UNIQUE INDEX work_item_comments_pkey ON public.work_item_comments USING btree (id);
CREATE UNIQUE INDEX work_item_idempotency_pkey ON public.work_item_idempotency USING btree (id);
CREATE UNIQUE INDEX work_item_tags_pkey ON public.work_item_tags USING btree (id);
CREATE UNIQUE INDEX work_item_watchers_pkey ON public.work_item_watchers USING btree (work_item_id, user_id);
CREATE UNIQUE INDEX work_items_pkey ON public.work_items USING btree (id);
CREATE UNIQUE INDEX workflow_bindings_pkey ON public.workflow_bindings USING btree (id);
CREATE UNIQUE INDEX workflow_bindings_workflow_template_id_work_item_type_key ON public.workflow_bindings USING btree (workflow_template_id, work_item_type);
CREATE UNIQUE INDEX workflow_graph_layouts_pkey ON public.workflow_graph_layouts USING btree (id);
CREATE UNIQUE INDEX workflow_graph_layouts_workflow_template_id_step_template_i_key ON public.workflow_graph_layouts USING btree (workflow_template_id, step_template_id);
CREATE UNIQUE INDEX workflow_instance_journal_pkey ON public.workflow_instance_journal USING btree (id);
CREATE UNIQUE INDEX workflow_instance_steps_pkey ON public.workflow_instance_steps USING btree (id);
CREATE UNIQUE INDEX workflow_instance_tasks_pkey ON public.workflow_instance_tasks USING btree (id);
CREATE UNIQUE INDEX workflow_instances_pkey ON public.workflow_instances USING btree (id);
CREATE UNIQUE INDEX workflow_project_bindings_pkey ON public.workflow_project_bindings USING btree (id);
CREATE UNIQUE INDEX workflow_step_assignments_pkey ON public.workflow_step_assignments USING btree (id);
CREATE UNIQUE INDEX workflow_step_task_templates_pkey ON public.workflow_step_task_templates USING btree (id);
CREATE UNIQUE INDEX workflow_step_task_templates_workflow_step_id_template_id_key ON public.workflow_step_task_templates USING btree (workflow_step_id, template_id);
CREATE UNIQUE INDEX workflow_step_templates_pkey ON public.workflow_step_templates USING btree (id);
CREATE UNIQUE INDEX workflow_step_templates_unique ON public.workflow_step_templates USING btree (workflow_template_id, name);
CREATE UNIQUE INDEX workflow_steps_pkey ON public.workflow_steps USING btree (id);
CREATE UNIQUE INDEX workflow_task_templates_pkey ON public.workflow_task_templates USING btree (id);
CREATE UNIQUE INDEX workflow_task_templates_unique ON public.workflow_task_templates USING btree (step_template_id, name);
CREATE UNIQUE INDEX workflow_template_edges_pkey ON public.workflow_template_edges USING btree (id);
CREATE UNIQUE INDEX workflow_template_nodes_pkey ON public.workflow_template_nodes USING btree (id);
CREATE UNIQUE INDEX workflow_templates_pkey ON public.workflow_templates USING btree (id);
CREATE UNIQUE INDEX workflow_templates_unique ON public.workflow_templates USING btree (name, version);
CREATE UNIQUE INDEX workflow_transitions_pkey ON public.workflow_transitions USING btree (id);
CREATE UNIQUE INDEX workflows_pkey ON public.workflows USING btree (id);
CREATE UNIQUE INDEX layer_pkey ON topology.layer USING btree (topology_id, layer_id);
CREATE UNIQUE INDEX layer_schema_name_table_name_feature_column_key ON topology.layer USING btree (schema_name, table_name, feature_column);
CREATE UNIQUE INDEX topology_name_key ON topology.topology USING btree (name);
CREATE UNIQUE INDEX topology_pkey ON topology.topology USING btree (id);
CREATE UNIQUE INDEX inventory_balances_pkey ON warehouse.inventory_balances USING btree (id);
CREATE UNIQUE INDEX issue_headers_pkey ON warehouse.issue_headers USING btree (id);
CREATE UNIQUE INDEX issue_lines_pkey ON warehouse.issue_lines USING btree (id);
CREATE INDEX ix_inventory_material ON warehouse.inventory_balances USING btree (material_id);
CREATE INDEX ix_inventory_project ON warehouse.inventory_balances USING btree (project_id);
CREATE INDEX ix_inventory_warehouse ON warehouse.inventory_balances USING btree (warehouse_id);
CREATE INDEX ix_issue_headers_mr ON warehouse.issue_headers USING btree (mr_id);
CREATE INDEX ix_issue_headers_project ON warehouse.issue_headers USING btree (project_id);
CREATE INDEX ix_issue_headers_warehouse ON warehouse.issue_headers USING btree (warehouse_id);
CREATE INDEX ix_issue_lines_issue ON warehouse.issue_lines USING btree (issue_id);
CREATE INDEX ix_issue_lines_material ON warehouse.issue_lines USING btree (material_id);
CREATE INDEX ix_issue_lines_mr_line ON warehouse.issue_lines USING btree (mr_line_id);
CREATE INDEX ix_locations_status ON warehouse.locations USING btree (status);
CREATE INDEX ix_locations_warehouse ON warehouse.locations USING btree (warehouse_id);
CREATE INDEX ix_locations_warehouse_zone_rack_level ON warehouse.locations USING btree (warehouse_id, zone, rack, level);
CREATE INDEX ix_mr_headers_package ON warehouse.mr_headers USING btree (package_id);
CREATE INDEX ix_mr_headers_project ON warehouse.mr_headers USING btree (project_id);
CREATE INDEX ix_mr_headers_warehouse ON warehouse.mr_headers USING btree (warehouse_id);
CREATE INDEX ix_mr_lines_material ON warehouse.mr_lines USING btree (material_id);
CREATE INDEX ix_mr_lines_mr ON warehouse.mr_lines USING btree (mr_id);
CREATE INDEX ix_pallet_items_last_receipt ON warehouse.pallet_items USING btree (last_receipt_line_id);
CREATE INDEX ix_pallet_items_material ON warehouse.pallet_items USING btree (material_id);
CREATE INDEX ix_pallet_items_origin ON warehouse.pallet_items USING btree (origin);
CREATE INDEX ix_pallet_movements_pallet_created ON warehouse.pallet_movements USING btree (pallet_id, created_at DESC);
CREATE INDEX ix_pallet_movements_ref_issue ON warehouse.pallet_movements USING btree (ref_issue_id);
CREATE INDEX ix_pallet_movements_ref_receipt ON warehouse.pallet_movements USING btree (ref_receipt_id);
CREATE INDEX ix_pallets_location ON warehouse.pallets USING btree (location_id);
CREATE INDEX ix_pallets_status ON warehouse.pallets USING btree (status);
CREATE INDEX ix_pallets_warehouse ON warehouse.pallets USING btree (warehouse_id);
CREATE INDEX ix_receipt_headers_project ON warehouse.receipt_headers USING btree (project_id);
CREATE INDEX ix_receipt_headers_project_zone ON warehouse.receipt_headers USING btree (project_id, building, floor, project_zone);
CREATE INDEX ix_receipt_headers_status ON warehouse.receipt_headers USING btree (status);
CREATE INDEX ix_receipt_headers_supplier ON warehouse.receipt_headers USING btree (supplier_id);
CREATE INDEX ix_receipt_headers_warehouse_date ON warehouse.receipt_headers USING btree (warehouse_id, receipt_date DESC);
CREATE INDEX ix_receipt_headers_work_item ON warehouse.receipt_headers USING btree (work_item_id);
CREATE INDEX ix_receipt_lines_boq_item ON warehouse.receipt_lines USING btree (boq_item_id);
CREATE INDEX ix_receipt_lines_location ON warehouse.receipt_lines USING btree (location_id);
CREATE INDEX ix_receipt_lines_material ON warehouse.receipt_lines USING btree (material_id);
CREATE INDEX ix_receipt_lines_origin ON warehouse.receipt_lines USING btree (origin);
CREATE INDEX ix_receipt_lines_pallet ON warehouse.receipt_lines USING btree (pallet_id);
CREATE INDEX ix_receipt_lines_receipt ON warehouse.receipt_lines USING btree (receipt_id);
CREATE INDEX ix_receipt_lines_source_mr ON warehouse.receipt_lines USING btree (source_mr_id, source_mr_line_id);
CREATE INDEX ix_receipt_lines_source_work_item ON warehouse.receipt_lines USING btree (source_work_item_id);
CREATE INDEX ix_warehouses_project ON warehouse.warehouses USING btree (project_id);
CREATE UNIQUE INDEX locations_pkey ON warehouse.locations USING btree (id);
CREATE UNIQUE INDEX mr_headers_pkey ON warehouse.mr_headers USING btree (id);
CREATE UNIQUE INDEX mr_lines_pkey ON warehouse.mr_lines USING btree (id);
CREATE UNIQUE INDEX pallet_items_pkey ON warehouse.pallet_items USING btree (id);
CREATE UNIQUE INDEX pallet_movements_pkey ON warehouse.pallet_movements USING btree (id);
CREATE UNIQUE INDEX pallets_pkey ON warehouse.pallets USING btree (id);
CREATE UNIQUE INDEX receipt_headers_pkey ON warehouse.receipt_headers USING btree (id);
CREATE UNIQUE INDEX receipt_lines_pkey ON warehouse.receipt_lines USING btree (id);
CREATE UNIQUE INDEX stocktake_headers_pkey ON warehouse.stocktake_headers USING btree (id);
CREATE UNIQUE INDEX stocktake_lines_pkey ON warehouse.stocktake_lines USING btree (id);
CREATE UNIQUE INDEX uq_inventory_balances_scope ON warehouse.inventory_balances USING btree (org_id, project_id, warehouse_id, material_id);
CREATE UNIQUE INDEX uq_pallet_items_pallet_material ON warehouse.pallet_items USING btree (pallet_id, material_id);
CREATE UNIQUE INDEX ux_inventory_balances_scope_material ON warehouse.inventory_balances USING btree (org_id, project_id, warehouse_id, material_id);
CREATE UNIQUE INDEX ux_inventory_org_project_wh_material ON warehouse.inventory_balances USING btree (org_id, project_id, warehouse_id, material_id);
CREATE UNIQUE INDEX ux_locations_wh_code ON warehouse.locations USING btree (warehouse_id, code);
CREATE UNIQUE INDEX ux_mr_headers_work_item ON warehouse.mr_headers USING btree (work_item_id);
CREATE UNIQUE INDEX ux_pallet_items_pallet_material ON warehouse.pallet_items USING btree (pallet_id, material_id);
CREATE UNIQUE INDEX ux_pallets_wh_code ON warehouse.pallets USING btree (warehouse_id, code);
CREATE UNIQUE INDEX ux_receipt_headers_org_code ON warehouse.receipt_headers USING btree (org_id, code) WHERE (code IS NOT NULL);
CREATE UNIQUE INDEX ux_warehouses_org_code ON warehouse.warehouses USING btree (org_id, code);
CREATE UNIQUE INDEX warehouses_pkey ON warehouse.warehouses USING btree (id);

-- Triggers
CREATE TRIGGER audit_approval_requests AFTER INSERT OR DELETE OR UPDATE ON public.approval_requests FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_configs AFTER INSERT OR DELETE OR UPDATE ON public.configs FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_contracts AFTER INSERT OR DELETE OR UPDATE ON public.contracts FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER enforce_workflow_contracts BEFORE INSERT OR UPDATE ON public.contracts FOR EACH ROW EXECUTE FUNCTION enforce_workflow();
CREATE TRIGGER update_contracts_updated_at BEFORE UPDATE ON public.contracts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER audit_departments AFTER INSERT OR DELETE OR UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_documents AFTER INSERT OR DELETE OR UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER enforce_workflow_documents BEFORE INSERT OR UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION enforce_workflow('optional');
CREATE TRIGGER trg_documents_set_updated_at BEFORE UPDATE ON public.documents FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER audit_notifications AFTER INSERT OR DELETE OR UPDATE ON public.notifications FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_organizations AFTER INSERT OR DELETE OR UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER audit_outbox_events AFTER INSERT OR DELETE OR UPDATE ON public.outbox_events FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_packages AFTER INSERT OR DELETE OR UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER enforce_workflow_packages BEFORE INSERT OR UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION enforce_workflow();
CREATE TRIGGER update_packages_updated_at BEFORE UPDATE ON public.packages FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER audit_project_members AFTER INSERT OR DELETE OR UPDATE ON public.project_members FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_projects AFTER INSERT OR DELETE OR UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER enforce_workflow_projects BEFORE INSERT OR UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION enforce_workflow('optional');
CREATE TRIGGER audit_projects_deleted AFTER INSERT OR DELETE OR UPDATE ON public.projects_deleted FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_roles AFTER INSERT OR DELETE OR UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER update_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_tags_set_updated_at BEFORE UPDATE ON public.tags FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER audit_tasks AFTER INSERT OR DELETE OR UPDATE ON public.tasks FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trig_update_progress_tasks AFTER UPDATE OF status ON public.tasks FOR EACH ROW WHEN ((new.is_deleted = false)) EXECUTE FUNCTION update_progress_tasks();
CREATE TRIGGER audit_tickets AFTER INSERT OR DELETE OR UPDATE ON public.tickets FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_timeline_dependencies AFTER INSERT OR DELETE OR UPDATE ON public.timeline_dependencies FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_timelines AFTER INSERT OR DELETE OR UPDATE ON public.timelines FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_timelines_extended AFTER INSERT OR DELETE OR UPDATE ON public.timelines FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER update_timelines_updated_at BEFORE UPDATE ON public.timelines FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER audit_user_departments AFTER INSERT OR DELETE OR UPDATE ON public.user_departments FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_user_devices AFTER INSERT OR DELETE OR UPDATE ON public.user_devices FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_user_preferences AFTER INSERT OR DELETE OR UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_users AFTER INSERT OR DELETE OR UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER audit_webhooks AFTER INSERT OR DELETE OR UPDATE ON public.webhooks FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trg_wi_cat_set_level_biu BEFORE INSERT OR UPDATE OF parent_id ON public.wi_categories FOR EACH ROW EXECUTE FUNCTION trg_wi_cat_set_level_biu();
CREATE TRIGGER trg_wi_categories_set_name_norm BEFORE INSERT OR UPDATE OF name ON public.wi_categories FOR EACH ROW EXECUTE FUNCTION f_wi_categories_set_name_norm();
CREATE TRIGGER audit_work_item_attachments AFTER INSERT OR DELETE OR UPDATE ON public.work_item_attachments FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trg_wi_idem_set_updated_at BEFORE UPDATE ON public.work_item_idempotency FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER audit_work_item_tags AFTER INSERT OR DELETE OR UPDATE ON public.work_item_tags FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_work_items AFTER INSERT OR DELETE OR UPDATE ON public.work_items FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.work_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_wfit_default_priority BEFORE INSERT ON public.workflow_instance_tasks FOR EACH ROW EXECUTE FUNCTION wfit_set_default_priority();
CREATE TRIGGER audit_workflow_instances AFTER INSERT OR DELETE OR UPDATE ON public.workflow_instances FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trig_sync_workitem_project BEFORE INSERT OR UPDATE ON public.workflow_instances FOR EACH ROW EXECUTE FUNCTION sync_workitem_project();
CREATE TRIGGER audit_workflow_project_bindings AFTER INSERT OR DELETE OR UPDATE ON public.workflow_project_bindings FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trg_wfpb_set_updated_at BEFORE UPDATE ON public.workflow_project_bindings FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();
CREATE TRIGGER audit_workflow_steps AFTER INSERT OR DELETE OR UPDATE ON public.workflow_steps FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_workflow_template_nodes AFTER INSERT OR DELETE OR UPDATE ON public.workflow_template_nodes FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER audit_workflow_templates AFTER INSERT OR DELETE OR UPDATE ON public.workflow_templates FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER trig_sync_wf_transition_steps BEFORE INSERT OR UPDATE ON public.workflow_transitions FOR EACH ROW EXECUTE FUNCTION sync_wf_transition_steps();
CREATE TRIGGER audit_workflows AFTER INSERT OR DELETE OR UPDATE ON public.workflows FOR EACH ROW EXECUTE FUNCTION log_audit();
CREATE TRIGGER layer_integrity_checks BEFORE DELETE OR UPDATE ON topology.layer FOR EACH ROW EXECUTE FUNCTION layertrigger();

-- Functions
CREATE OR REPLACE FUNCTION estimating.rebuild_estimate_totals(p_version_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
begin
  insert into estimating.estimate_totals as t (
    estimate_version_id,
    items_count,
    amount_material,
    amount_labor,
    amount_equipment,
    amount_service,
    overhead,
    tax,
    profit,
    total_amount,
    updated_at
  )
  select
    v.id,
    count(*)::int,
    coalesce(sum(case when b.item_type='material'  then b.amount end),0),
    coalesce(sum(case when b.item_type='labor'     then b.amount end),0),
    coalesce(sum(case when b.item_type='equipment' then b.amount end),0),
    coalesce(sum(case when b.item_type='service'   then b.amount end),0),
    0::numeric,  -- tuỳ chính sách, cộng sau
    0::numeric,
    0::numeric,
    coalesce(sum(b.amount),0),
    now()
  from estimating.estimate_versions v
  left join estimating.boq_items b on b.estimate_version_id = v.id
  where v.id = p_version_id
  group by v.id
  on conflict (estimate_version_id) do update
  set
    items_count      = excluded.items_count,
    amount_material  = excluded.amount_material,
    amount_labor     = excluded.amount_labor,
    amount_equipment = excluded.amount_equipment,
    amount_service   = excluded.amount_service,
    total_amount     = excluded.total_amount,
    updated_at       = now();
end$function$
;

CREATE OR REPLACE FUNCTION log.audit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (current_setting('app.current_user')::uuid, TG_OP, TG_TABLE_NAME, NEW.id, CURRENT_TIMESTAMP, row_to_json(NEW));
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (current_setting('app.current_user')::uuid, TG_OP, TG_TABLE_NAME, NEW.id, CURRENT_TIMESTAMP, row_to_json(NEW));
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (current_setting('app.current_user')::uuid, TG_OP, TG_TABLE_NAME, OLD.id, CURRENT_TIMESTAMP, row_to_json(OLD));
    END IF;
    RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public._postgis_deprecate(oldname text, newname text, version text)
 RETURNS void
 LANGUAGE plpgsql
 IMMUTABLE STRICT COST 250
AS $function$
DECLARE
  curver_text text;
BEGIN
  --
  -- Raises a NOTICE if it was deprecated in this version,
  -- a WARNING if in a previous version (only up to minor version checked)
  --
	curver_text := '3.6.0';
	IF pg_catalog.split_part(curver_text,'.',1)::int > pg_catalog.split_part(version,'.',1)::int OR
	   ( pg_catalog.split_part(curver_text,'.',1) = pg_catalog.split_part(version,'.',1) AND
		 pg_catalog.split_part(curver_text,'.',2) != split_part(version,'.',2) )
	THEN
	  RAISE WARNING '% signature was deprecated in %. Please use %', oldname, version, newname;
	ELSE
	  RAISE DEBUG '% signature was deprecated in %. Please use %', oldname, version, newname;
	END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public._postgis_index_extent(tbl regclass, col text)
 RETURNS box2d
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis-3', $function$_postgis_gserialized_index_extent$function$
;

CREATE OR REPLACE FUNCTION public._postgis_join_selectivity(regclass, text, regclass, text, text DEFAULT '2'::text)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$_postgis_gserialized_joinsel$function$
;

CREATE OR REPLACE FUNCTION public._postgis_pgsql_version()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
	SELECT CASE WHEN pg_catalog.split_part(s,'.',1)::integer > 9 THEN pg_catalog.split_part(s,'.',1) || '0'
	ELSE pg_catalog.split_part(s,'.', 1) || pg_catalog.split_part(s,'.', 2) END AS v
	FROM pg_catalog.substring(version(), E'PostgreSQL ([0-9\\.]+)') AS s;
$function$
;

CREATE OR REPLACE FUNCTION public._postgis_scripts_pgsql_version()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$SELECT '180'::text AS version$function$
;

CREATE OR REPLACE FUNCTION public._postgis_selectivity(tbl regclass, att_name text, geom geometry, mode text DEFAULT '2'::text)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$_postgis_gserialized_sel$function$
;

CREATE OR REPLACE FUNCTION public._postgis_stats(tbl regclass, att_name text, text DEFAULT '2'::text)
 RETURNS text
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$_postgis_gserialized_stats$function$
;

CREATE OR REPLACE FUNCTION public._st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dfullywithin3d$function$
;

CREATE OR REPLACE FUNCTION public._st_3ddwithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dwithin3d$function$
;

CREATE OR REPLACE FUNCTION public._st_3dintersects(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_3DIntersects$function$
;

CREATE OR REPLACE FUNCTION public._st_asgml(integer, geometry, integer, integer, text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asGML$function$
;

CREATE OR REPLACE FUNCTION public._st_asx3d(integer, geometry, integer, integer, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asX3D$function$
;

CREATE OR REPLACE FUNCTION public._st_bestsrid(geography, geography)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geography_bestsrid$function$
;

CREATE OR REPLACE FUNCTION public._st_bestsrid(geography)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geography_bestsrid$function$
;

CREATE OR REPLACE FUNCTION public._st_contains(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$contains$function$
;

CREATE OR REPLACE FUNCTION public._st_containsproperly(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$containsproperly$function$
;

CREATE OR REPLACE FUNCTION public._st_coveredby(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$coveredby$function$
;

CREATE OR REPLACE FUNCTION public._st_coveredby(geog1 geography, geog2 geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_coveredby$function$
;

CREATE OR REPLACE FUNCTION public._st_covers(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$covers$function$
;

CREATE OR REPLACE FUNCTION public._st_covers(geog1 geography, geog2 geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_covers$function$
;

CREATE OR REPLACE FUNCTION public._st_crosses(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$crosses$function$
;

CREATE OR REPLACE FUNCTION public._st_dfullywithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dfullywithin$function$
;

CREATE OR REPLACE FUNCTION public._st_distancetree(geography, geography, double precision, boolean)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_distance_tree$function$
;

CREATE OR REPLACE FUNCTION public._st_distancetree(geography, geography)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$SELECT public._ST_DistanceTree($1, $2, 0.0, true)$function$
;

CREATE OR REPLACE FUNCTION public._st_distanceuncached(geography, geography, double precision, boolean)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_distance_uncached$function$
;

CREATE OR REPLACE FUNCTION public._st_distanceuncached(geography, geography, boolean)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$SELECT public._ST_DistanceUnCached($1, $2, 0.0, $3)$function$
;

CREATE OR REPLACE FUNCTION public._st_distanceuncached(geography, geography)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$SELECT public._ST_DistanceUnCached($1, $2, 0.0, true)$function$
;

CREATE OR REPLACE FUNCTION public._st_dwithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dwithin$function$
;

CREATE OR REPLACE FUNCTION public._st_dwithin(geog1 geography, geog2 geography, tolerance double precision, use_spheroid boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_dwithin$function$
;

CREATE OR REPLACE FUNCTION public._st_dwithinuncached(geography, geography, double precision, boolean)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_dwithin_uncached$function$
;

CREATE OR REPLACE FUNCTION public._st_dwithinuncached(geography, geography, double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE
AS $function$SELECT $1 OPERATOR(public.&&) public._ST_Expand($2,$3) AND $2 OPERATOR(public.&&) public._ST_Expand($1,$3) AND public._ST_DWithinUnCached($1, $2, $3, true)$function$
;

CREATE OR REPLACE FUNCTION public._st_equals(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Equals$function$
;

CREATE OR REPLACE FUNCTION public._st_expand(geography, double precision)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geography_expand$function$
;

CREATE OR REPLACE FUNCTION public._st_geomfromgml(text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$geom_from_gml$function$
;

CREATE OR REPLACE FUNCTION public._st_intersects(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Intersects$function$
;

CREATE OR REPLACE FUNCTION public._st_linecrossingdirection(line1 geometry, line2 geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_LineCrossingDirection$function$
;

CREATE OR REPLACE FUNCTION public._st_longestline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_longestline2d$function$
;

CREATE OR REPLACE FUNCTION public._st_maxdistance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_maxdistance2d_linestring$function$
;

CREATE OR REPLACE FUNCTION public._st_orderingequals(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_same$function$
;

CREATE OR REPLACE FUNCTION public._st_overlaps(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$overlaps$function$
;

CREATE OR REPLACE FUNCTION public._st_pointoutside(geography)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/postgis-3', $function$geography_point_outside$function$
;

CREATE OR REPLACE FUNCTION public._st_sortablehash(geom geometry)
 RETURNS bigint
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$_ST_SortableHash$function$
;

CREATE OR REPLACE FUNCTION public._st_touches(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$touches$function$
;

CREATE OR REPLACE FUNCTION public._st_voronoi(g1 geometry, clip geometry DEFAULT NULL::geometry, tolerance double precision DEFAULT 0.0, return_polygons boolean DEFAULT true)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 5000
AS '$libdir/postgis-3', $function$ST_Voronoi$function$
;

CREATE OR REPLACE FUNCTION public._st_within(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$SELECT public._ST_Contains($2,$1)$function$
;

CREATE OR REPLACE FUNCTION public.addgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	rec RECORD;
	sr varchar;
	real_schema name;
	sql text;
	new_srid integer;

BEGIN

	-- Verify geometry type
	IF (postgis_type_name(new_type,new_dim) IS NULL )
	THEN
		RAISE EXCEPTION 'Invalid type name "%(%)" - valid ones are:
	POINT, MULTIPOINT,
	LINESTRING, MULTILINESTRING,
	POLYGON, MULTIPOLYGON,
	CIRCULARSTRING, COMPOUNDCURVE, MULTICURVE,
	CURVEPOLYGON, MULTISURFACE,
	GEOMETRY, GEOMETRYCOLLECTION,
	POINTM, MULTIPOINTM,
	LINESTRINGM, MULTILINESTRINGM,
	POLYGONM, MULTIPOLYGONM,
	CIRCULARSTRINGM, COMPOUNDCURVEM, MULTICURVEM
	CURVEPOLYGONM, MULTISURFACEM, TRIANGLE, TRIANGLEM,
	POLYHEDRALSURFACE, POLYHEDRALSURFACEM, TIN, TINM
	or GEOMETRYCOLLECTIONM', new_type, new_dim;
		RETURN 'fail';
	END IF;

	-- Verify dimension
	IF ( (new_dim >4) OR (new_dim <2) ) THEN
		RAISE EXCEPTION 'invalid dimension';
		RETURN 'fail';
	END IF;

	IF ( (new_type LIKE '%M') AND (new_dim!=3) ) THEN
		RAISE EXCEPTION 'TypeM needs 3 dimensions';
		RETURN 'fail';
	END IF;

	-- Verify SRID
	IF ( new_srid_in > 0 ) THEN
		IF new_srid_in > 998999 THEN
			RAISE EXCEPTION 'AddGeometryColumn() - SRID must be <= %', 998999;
		END IF;
		new_srid := new_srid_in;
		SELECT SRID INTO sr FROM public.spatial_ref_sys WHERE SRID = new_srid;
		IF NOT FOUND THEN
			RAISE EXCEPTION 'AddGeometryColumn() - invalid SRID';
			RETURN 'fail';
		END IF;
	ELSE
		new_srid := public.ST_SRID('POINT EMPTY'::public.geometry);
		IF ( new_srid_in != new_srid ) THEN
			RAISE NOTICE 'SRID value % converted to the officially unknown SRID value %', new_srid_in, new_srid;
		END IF;
	END IF;

	-- Verify schema
	IF ( schema_name IS NOT NULL AND schema_name != '' ) THEN
		sql := 'SELECT nspname FROM pg_namespace ' ||
			'WHERE text(nspname) = ' || quote_literal(schema_name) ||
			'LIMIT 1';
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Schema % is not a valid schemaname', quote_literal(schema_name);
			RETURN 'fail';
		END IF;
	END IF;

	IF ( real_schema IS NULL ) THEN
		RAISE DEBUG 'Detecting schema';
		sql := 'SELECT n.nspname AS schemaname ' ||
			'FROM pg_catalog.pg_class c ' ||
			  'JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace ' ||
			'WHERE c.relkind = ' || quote_literal('r') ||
			' AND n.nspname NOT IN (' || quote_literal('pg_catalog') || ', ' || quote_literal('pg_toast') || ')' ||
			' AND pg_catalog.pg_table_is_visible(c.oid)' ||
			' AND c.relname = ' || quote_literal(table_name);
		RAISE DEBUG '%', sql;
		EXECUTE sql INTO real_schema;

		IF ( real_schema IS NULL ) THEN
			RAISE EXCEPTION 'Table % does not occur in the search_path', quote_literal(table_name);
			RETURN 'fail';
		END IF;
	END IF;

	-- Add geometry column to table
	IF use_typmod THEN
		 sql := 'ALTER TABLE ' ||
			quote_ident(real_schema) || '.' || quote_ident(table_name)
			|| ' ADD COLUMN ' || quote_ident(column_name) ||
			' geometry(' || public.postgis_type_name(new_type, new_dim) || ', ' || new_srid::text || ')';
		RAISE DEBUG '%', sql;
	ELSE
		sql := 'ALTER TABLE ' ||
			quote_ident(real_schema) || '.' || quote_ident(table_name)
			|| ' ADD COLUMN ' || quote_ident(column_name) ||
			' geometry ';
		RAISE DEBUG '%', sql;
	END IF;
	EXECUTE sql;

	IF NOT use_typmod THEN
		-- Add table CHECKs
		sql := 'ALTER TABLE ' ||
			quote_ident(real_schema) || '.' || quote_ident(table_name)
			|| ' ADD CONSTRAINT '
			|| quote_ident('enforce_srid_' || column_name)
			|| ' CHECK (st_srid(' || quote_ident(column_name) ||
			') = ' || new_srid::text || ')' ;
		RAISE DEBUG '%', sql;
		EXECUTE sql;

		sql := 'ALTER TABLE ' ||
			quote_ident(real_schema) || '.' || quote_ident(table_name)
			|| ' ADD CONSTRAINT '
			|| quote_ident('enforce_dims_' || column_name)
			|| ' CHECK (st_ndims(' || quote_ident(column_name) ||
			') = ' || new_dim::text || ')' ;
		RAISE DEBUG '%', sql;
		EXECUTE sql;

		IF ( NOT (new_type = 'GEOMETRY')) THEN
			sql := 'ALTER TABLE ' ||
				quote_ident(real_schema) || '.' || quote_ident(table_name) || ' ADD CONSTRAINT ' ||
				quote_ident('enforce_geotype_' || column_name) ||
				' CHECK (GeometryType(' ||
				quote_ident(column_name) || ')=' ||
				quote_literal(new_type) || ' OR (' ||
				quote_ident(column_name) || ') is null)';
			RAISE DEBUG '%', sql;
			EXECUTE sql;
		END IF;
	END IF;

	RETURN
		real_schema || '.' ||
		table_name || '.' || column_name ||
		' SRID:' || new_srid::text ||
		' TYPE:' || new_type ||
		' DIMS:' || new_dim::text || ' ';
END;
$function$
;

CREATE OR REPLACE FUNCTION public.addgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
	ret  text;
BEGIN
	SELECT public.AddGeometryColumn('',$1,$2,$3,$4,$5,$6,$7) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.addgeometrycolumn(table_name character varying, column_name character varying, new_srid integer, new_type character varying, new_dim integer, use_typmod boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	ret  text;
BEGIN
	SELECT public.AddGeometryColumn('','',$1,$2,$3,$4,$5, $6) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.armor(bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_armor$function$
;

CREATE OR REPLACE FUNCTION public.armor(bytea, text[], text[])
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_armor$function$
;

CREATE OR REPLACE FUNCTION public.box(geometry)
 RETURNS box
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_BOX$function$
;

CREATE OR REPLACE FUNCTION public.box(box3d)
 RETURNS box
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_to_BOX$function$
;

CREATE OR REPLACE FUNCTION public.box2d(geometry)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_BOX2D$function$
;

CREATE OR REPLACE FUNCTION public.box2d(box3d)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_to_BOX2D$function$
;

CREATE OR REPLACE FUNCTION public.box2d_in(cstring)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX2D_in$function$
;

CREATE OR REPLACE FUNCTION public.box2d_out(box2d)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX2D_out$function$
;

CREATE OR REPLACE FUNCTION public.box2df_in(cstring)
 RETURNS box2df
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$box2df_in$function$
;

CREATE OR REPLACE FUNCTION public.box2df_out(box2df)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$box2df_out$function$
;

CREATE OR REPLACE FUNCTION public.box3d(geometry)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_BOX3D$function$
;

CREATE OR REPLACE FUNCTION public.box3d(box2d)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX2D_to_BOX3D$function$
;

CREATE OR REPLACE FUNCTION public.box3d_in(cstring)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_in$function$
;

CREATE OR REPLACE FUNCTION public.box3d_out(box3d)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_out$function$
;

CREATE OR REPLACE FUNCTION public.box3dtobox(box3d)
 RETURNS box
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_to_BOX$function$
;

CREATE OR REPLACE FUNCTION public.bytea(geometry)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_bytea$function$
;

CREATE OR REPLACE FUNCTION public.bytea(geography)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_to_bytea$function$
;

CREATE OR REPLACE FUNCTION public.calculate_project_progress()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Tính progress từ tasks qua packages HOẶC direct project
    UPDATE projects p
    SET progress = (
        SELECT AVG(CASE WHEN t.status = 'done' THEN 100 ELSE 0 END)
        FROM tasks t
        LEFT JOIN packages pk ON t.package_id = pk.id
        WHERE pk.project_id = p.id OR t.project_id = p.id  -- Handle both cases
    )
    WHERE p.id = COALESCE((SELECT pk.project_id FROM packages pk WHERE pk.id = NEW.package_id), NEW.project_id);

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.contains_2d(box2df, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_box2df_geom_2d$function$
;

CREATE OR REPLACE FUNCTION public.contains_2d(box2df, box2df)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_box2df_box2df_2d$function$
;

CREATE OR REPLACE FUNCTION public.contains_2d(geometry, box2df)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 1
AS $function$SELECT $2 OPERATOR(public.@) $1;$function$
;

CREATE OR REPLACE PROCEDURE public.create_workflow_full(IN _json jsonb)
 LANGUAGE plpgsql
AS $procedure$
DECLARE
  v_workflow_id           uuid;
  v_instance_id           uuid;
  v_scope                 text;
  v_trigger_mode          text;
  v_scheduled_at          timestamptz;
  v_create_instance_now   boolean;
  v_org_id                uuid;
  v_attach_project_id     uuid;
  v_code                  text;
  v_name                  text;
  v_desc                  text;

  step                    jsonb;
  step_idx                int := 0;
  v_step_id               uuid;

  assign                  jsonb;
  tmpl                    jsonb;
  item                    jsonb;
  v_template_id           uuid;

  t                       jsonb;
BEGIN
  -- 0) VALIDATION & MAP FIELDS
  IF _json IS NULL THEN
    RAISE EXCEPTION 'Input JSON is null';
  END IF;

  v_org_id               := NULLIF(_json->>'org_id','')::uuid;
  v_scope                := COALESCE(_json->'workflow'->>'scope','independent');         -- 'independent' | 'project'
  v_trigger_mode         := COALESCE(_json->'workflow'->>'trigger_mode','immediate');    -- 'immediate' | 'scheduled'
  v_scheduled_at         := NULLIF(_json->'workflow'->>'scheduled_start_at','')::timestamptz;
  v_create_instance_now  := COALESCE((_json->>'create_instance_now')::boolean, false);
  v_attach_project_id    := NULLIF(_json->'workflow'->>'attach_to_project_id','')::uuid;
  v_code                 := _json->'workflow'->>'code';
  v_name                 := _json->'workflow'->>'name';
  v_desc                 := _json->'workflow'->>'description';

  IF v_scope = 'project' AND v_attach_project_id IS NULL THEN
     RAISE EXCEPTION 'scope=project requires attach_to_project_id';
  END IF;

  IF v_code IS NULL OR v_name IS NULL THEN
     RAISE EXCEPTION 'workflow.code and workflow.name are required';
  END IF;

  -- 1) INSERT WORKFLOW (DEFINITION)
  INSERT INTO workflows (id, code, name, scope, description, created_at)
  VALUES (gen_random_uuid(), v_code, v_name, v_scope, v_desc, now())
  RETURNING id INTO v_workflow_id;

  -- 2) INSERT STEPS + ASSIGNMENTS + TEMPLATES + ITEMS + MAP STEP<->TEMPLATE
  step_idx := 0;
  FOR step IN SELECT * FROM jsonb_array_elements(COALESCE(_json->'steps','[]'::jsonb))
  LOOP
    step_idx := step_idx + 1;

    INSERT INTO workflow_steps (id, workflow_id, name, sort_order, meta)
    VALUES (
      gen_random_uuid(),
      v_workflow_id,
      step->>'name',
      step_idx,
      jsonb_build_object(
        'key', step->>'key',
        'sla_hours', COALESCE((step->>'sla_hours')::int, 24)
      )
    )
    RETURNING id INTO v_step_id;

    -- 2.1) step assignments
    FOR assign IN SELECT * FROM jsonb_array_elements(COALESCE(step->'assignments','[]'::jsonb))
    LOOP
      INSERT INTO workflow_step_assignments(
        id, workflow_step_id, department_id, user_id, role_in_step, created_at
      )
      VALUES (
        gen_random_uuid(),
        v_step_id,
        NULLIF(assign->>'department_id','')::uuid,
        NULLIF(assign->>'user_id','')::uuid,
        assign->>'role',
        now()
      );
    END LOOP;

    -- 2.2) step templates & items & map
    FOR tmpl IN SELECT * FROM jsonb_array_elements(COALESCE(step->'templates','[]'::jsonb))
    LOOP
      INSERT INTO task_templates (
        id, org_id, name, description, is_active, created_at
      )
      VALUES (
        gen_random_uuid(),
        v_org_id,
        tmpl->>'name',
        NULL,
        true,
        now()
      )
      RETURNING id INTO v_template_id;

      -- items
      FOR item IN SELECT * FROM jsonb_array_elements(COALESCE(tmpl->'items','[]'::jsonb))
      LOOP
        INSERT INTO task_template_items(
          id, template_id, title, due_days_offset, required, sort_order, created_at
        )
        VALUES (
          gen_random_uuid(),
          v_template_id,
          item->>'title',
          COALESCE((item->>'due_days_offset')::int, 0),
          COALESCE((item->>'required')::boolean, true),
          COALESCE((item->>'sort_order')::int, 0),
          now()
        );
      END LOOP;

      -- map step -> template
      INSERT INTO workflow_step_task_templates (id, workflow_step_id, template_id, created_at)
      VALUES (gen_random_uuid(), v_step_id, v_template_id, now())
      ON CONFLICT (workflow_step_id, template_id) DO NOTHING;
    END LOOP;
  END LOOP;

  -- 3) TRANSITIONS (forward/back/branch + condition_expr)
  FOR t IN SELECT * FROM jsonb_array_elements(COALESCE(_json->'transitions','[]'::jsonb))
  LOOP
     INSERT INTO workflow_transitions (
       id, workflow_id, from_step_id, to_step_id, transition_type, condition_expr, label, created_at
     )
     SELECT
       gen_random_uuid(),
       v_workflow_id,
       fs_from.id,
       fs_to.id,
       COALESCE(t->>'type','forward'),
       NULLIF(t->'condition_expr','null'::jsonb),
       t->>'label',
       now()
     FROM workflow_steps fs_from
     JOIN workflow_steps fs_to
       ON fs_to.workflow_id = fs_from.workflow_id
     WHERE fs_from.workflow_id = v_workflow_id
       AND (fs_from.meta->>'key') = t->>'from_key'
       AND (fs_to.meta->>'key')   = t->>'to_key';
  END LOOP;

  -- 4) (OPTIONAL) CREATE INSTANCE RIGHT AWAY
  IF v_create_instance_now THEN
    INSERT INTO workflow_instances (
      id, workflow_id, record_type, record_id, status, trigger_mode, scheduled_start_at, created_at
    )
    VALUES (
      gen_random_uuid(),
      v_workflow_id,
      CASE WHEN v_scope='project' THEN 'project' ELSE NULL END,
      CASE WHEN v_scope='project' THEN v_attach_project_id ELSE NULL END,
      CASE WHEN v_trigger_mode='scheduled' THEN 'pending' ELSE 'running' END,
      v_trigger_mode,
      v_scheduled_at,
      now()
    )
    RETURNING id INTO v_instance_id;
  END IF;

  -- 5) EXPOSE RESULT VIA TEMP TABLE (PER SESSION)
  CREATE TEMP TABLE IF NOT EXISTS tmp_create_workflow_result(
    workflow_id uuid,
    workflow_instance_id uuid
  ) ON COMMIT DROP;

  TRUNCATE tmp_create_workflow_result;
  INSERT INTO tmp_create_workflow_result VALUES (v_workflow_id, v_instance_id);

  RAISE NOTICE 'create_workflow_full OK. workflow_id=%, instance_id=%', v_workflow_id, v_instance_id;

EXCEPTION WHEN OTHERS THEN
  -- Gắn thêm ngữ cảnh để dễ trace log
  RAISE;
END;
$procedure$
;

CREATE OR REPLACE FUNCTION public.crypt(text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_crypt$function$
;

CREATE OR REPLACE FUNCTION public.dearmor(text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_dearmor$function$
;

CREATE OR REPLACE FUNCTION public.decrypt(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_decrypt$function$
;

CREATE OR REPLACE FUNCTION public.decrypt_iv(bytea, bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_decrypt_iv$function$
;

CREATE OR REPLACE FUNCTION public.digest(text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_digest$function$
;

CREATE OR REPLACE FUNCTION public.digest(bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_digest$function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrycolumn(catalog_name character varying, schema_name character varying, table_name character varying, column_name character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	myrec RECORD;
	okay boolean;
	real_schema name;

BEGIN

	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = false;

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := true;
		END LOOP;

		IF ( okay <>  true ) THEN
			RAISE NOTICE 'Invalid schema name - using current_schema()';
			SELECT current_schema() into real_schema;
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT current_schema() into real_schema;
	END IF;

	-- Find out if the column is in the geometry_columns table
	okay = false;
	FOR myrec IN SELECT * from public.geometry_columns where f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := true;
	END LOOP;
	IF (okay <> true) THEN
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN false;
	END IF;

	-- Remove table column
	EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) || '.' ||
		quote_ident(table_name) || ' DROP COLUMN ' ||
		quote_ident(column_name);

	RETURN real_schema || '.' || table_name || '.' || column_name ||' effectively removed.';

END;
$function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrycolumn(schema_name character varying, table_name character varying, column_name character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	ret text;
BEGIN
	SELECT public.DropGeometryColumn('',$1,$2,$3) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrycolumn(table_name character varying, column_name character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	ret text;
BEGIN
	SELECT public.DropGeometryColumn('','',$1,$2) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrytable(catalog_name character varying, schema_name character varying, table_name character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	real_schema name;

BEGIN

	IF ( schema_name = '' ) THEN
		SELECT current_schema() into real_schema;
	ELSE
		real_schema = schema_name;
	END IF;

	-- TODO: Should we warn if table doesn't exist probably instead just saying dropped
	-- Remove table
	EXECUTE 'DROP TABLE IF EXISTS '
		|| quote_ident(real_schema) || '.' ||
		quote_ident(table_name) || ' RESTRICT';

	RETURN
		real_schema || '.' ||
		table_name ||' dropped.';

END;
$function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrytable(schema_name character varying, table_name character varying)
 RETURNS text
 LANGUAGE sql
 STRICT
AS $function$ SELECT public.DropGeometryTable('',$1,$2) $function$
;

CREATE OR REPLACE FUNCTION public.dropgeometrytable(table_name character varying)
 RETURNS text
 LANGUAGE sql
 STRICT
AS $function$ SELECT public.DropGeometryTable('','',$1) $function$
;

CREATE OR REPLACE FUNCTION public.encrypt(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_encrypt$function$
;

CREATE OR REPLACE FUNCTION public.encrypt_iv(bytea, bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_encrypt_iv$function$
;

CREATE OR REPLACE FUNCTION public.enforce_workflow()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
 v_mode text := COALESCE(TG_ARGV[0], 'required'); -- default = required để không “lỏng” ngoài ý muốn
BEGIN
 -- Chỉ enforce khi v_mode = 'required'
 IF v_mode = 'required' AND NEW.workflow_id IS NULL THEN
   RAISE EXCEPTION 'Workflow ID is required for this module (table=%).',
     TG_TABLE_NAME;
 END IF;
 RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.equals(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_Equals$function$
;

CREATE OR REPLACE FUNCTION public.f_crm_template_suggest(_org_id uuid, _work_item_type text, _category_id uuid, _subcategory_id uuid)
 RETURNS TABLE(workflow_template_id uuid, defaults_json jsonb, matched_on text, template_status text)
 LANGUAGE sql
 STABLE
AS $function$
  SELECT
    m.workflow_template_id,
    m.defaults_json,
    CASE
      WHEN m.subcategory_id IS NOT NULL THEN 'subcategory'
      WHEN m.category_id    IS NOT NULL THEN 'category'
      ELSE 'default'
    END AS matched_on,
    m.template_status
  FROM mv_crm_template_suggestions m
  WHERE m.org_id = _org_id
    AND m.work_item_type = _work_item_type
    AND (
         (m.subcategory_id IS NOT NULL AND m.subcategory_id = _subcategory_id)
      OR (m.category_id    IS NOT NULL AND m.category_id    = _category_id)
      OR (m.category_id IS NULL AND m.subcategory_id IS NULL)
    )
  ORDER BY m.specificity DESC,
           (CASE WHEN m.template_status IN ('active','published') THEN 0 ELSE 1 END),
           m.updated_at DESC
  LIMIT 1;
$function$
;

CREATE OR REPLACE FUNCTION public.f_unaccent_immutable(character varying)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
SELECT public.unaccent($1)
$function$
;

CREATE OR REPLACE FUNCTION public.f_wi_cat_compute_level(_id uuid, _parent_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_level integer := 1;
  v_parent uuid := _parent_id;
  v_guard int := 0;
BEGIN
  -- nếu không có parent -> level = 1
  IF v_parent IS NULL THEN
    RETURN 1;
  END IF;

  -- leo lên tới gốc, tránh vòng lặp
  WHILE v_parent IS NOT NULL LOOP
    v_level := v_level + 1;
    SELECT parent_id INTO v_parent FROM public.wi_categories WHERE id = v_parent;
    v_guard := v_guard + 1;
    IF v_guard > 64 THEN
      -- tránh cycle vô hạn
      RAISE EXCEPTION 'wi_categories: possible cycle detected for id %', _id;
    END IF;
  END LOOP;

  RETURN v_level;
END$function$
;

CREATE OR REPLACE FUNCTION public.f_wi_categories_set_name_norm()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.name_norm := unaccent(lower(NEW.name));
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.f_wi_sync_legacy_cols()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
 -- Đồng bộ 1 chiều khi một phía thiếu
 IF NEW.type IS NULL AND NEW.ref_type IS NOT NULL THEN
   NEW.type := NEW.ref_type;
 ELSIF NEW.ref_type IS NULL AND NEW.type IS NOT NULL THEN
   NEW.ref_type := NEW.type;
 END IF;
 IF NEW.code IS NULL AND NEW.ref_code IS NOT NULL THEN
   NEW.code := NEW.ref_code;
 ELSIF NEW.ref_code IS NULL AND NEW.code IS NOT NULL THEN
   NEW.ref_code := NEW.code;
 END IF;
 RETURN NEW;
END$function$
;

CREATE OR REPLACE FUNCTION public.find_srid(character varying, character varying, character varying)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE PARALLEL SAFE STRICT
AS $function$
DECLARE
	schem varchar =  $1;
	tabl varchar = $2;
	sr int4;
BEGIN
-- if the table contains a . and the schema is empty
-- split the table into a schema and a table
-- otherwise drop through to default behavior
	IF ( schem = '' and strpos(tabl,'.') > 0 ) THEN
	 schem = substr(tabl,1,strpos(tabl,'.')-1);
	 tabl = substr(tabl,length(schem)+2);
	END IF;

	select SRID into sr from public.geometry_columns where (f_table_schema = schem or schem = '') and f_table_name = tabl and f_geometry_column = $3;
	IF NOT FOUND THEN
	   RAISE EXCEPTION 'find_srid() - could not find the corresponding SRID - is the geometry registered in the GEOMETRY_COLUMNS table?  Is there an uppercase/lowercase mismatch?';
	END IF;
	return sr;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.fips_mode()
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_check_fipsmode$function$
;

CREATE OR REPLACE FUNCTION public.gen_random_bytes(integer)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_random_bytes$function$
;

CREATE OR REPLACE FUNCTION public.gen_random_uuid()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/pgcrypto', $function$pg_random_uuid$function$
;

CREATE OR REPLACE FUNCTION public.gen_salt(text)
 RETURNS text
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_gen_salt$function$
;

CREATE OR REPLACE FUNCTION public.gen_salt(text, integer)
 RETURNS text
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_gen_salt_rounds$function$
;

CREATE OR REPLACE FUNCTION public.geog_brin_inclusion_add_value(internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geog_brin_inclusion_add_value$function$
;

CREATE OR REPLACE FUNCTION public.geog_brin_inclusion_merge(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geog_brin_inclusion_merge$function$
;

CREATE OR REPLACE FUNCTION public.geography(geography, integer, boolean)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_enforce_typmod$function$
;

CREATE OR REPLACE FUNCTION public.geography(bytea)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_from_binary$function$
;

CREATE OR REPLACE FUNCTION public.geography(geometry)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_from_geometry$function$
;

CREATE OR REPLACE FUNCTION public.geography_analyze(internal)
 RETURNS boolean
 LANGUAGE c
 STRICT
AS '$libdir/postgis-3', $function$gserialized_analyze_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_cmp(geography, geography)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_cmp$function$
;

CREATE OR REPLACE FUNCTION public.geography_distance_knn(geography, geography)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 100
AS '$libdir/postgis-3', $function$geography_distance_knn$function$
;

CREATE OR REPLACE FUNCTION public.geography_eq(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_eq$function$
;

CREATE OR REPLACE FUNCTION public.geography_ge(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_ge$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_compress(internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_compress$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_consistent(internal, geography, integer)
 RETURNS boolean
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_consistent$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_decompress(internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_decompress$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_distance(internal, geography, integer)
 RETURNS double precision
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_geog_distance$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_penalty(internal, internal, internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_penalty$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_picksplit(internal, internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_picksplit$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_same(box2d, box2d, internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_same$function$
;

CREATE OR REPLACE FUNCTION public.geography_gist_union(bytea, internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$gserialized_gist_union$function$
;

CREATE OR REPLACE FUNCTION public.geography_gt(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_gt$function$
;

CREATE OR REPLACE FUNCTION public.geography_in(cstring, oid, integer)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_in$function$
;

CREATE OR REPLACE FUNCTION public.geography_le(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_le$function$
;

CREATE OR REPLACE FUNCTION public.geography_lt(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_lt$function$
;

CREATE OR REPLACE FUNCTION public.geography_out(geography)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_out$function$
;

CREATE OR REPLACE FUNCTION public.geography_overlaps(geography, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.geography_recv(internal, oid, integer)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_recv$function$
;

CREATE OR REPLACE FUNCTION public.geography_send(geography)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_send$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_choose_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_choose_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_compress_nd(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_compress_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_config_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_config_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_inner_consistent_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_inner_consistent_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_leaf_consistent_nd(internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_leaf_consistent_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_spgist_picksplit_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_picksplit_nd$function$
;

CREATE OR REPLACE FUNCTION public.geography_typmod_in(cstring[])
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_typmod_in$function$
;

CREATE OR REPLACE FUNCTION public.geography_typmod_out(integer)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_typmod_out$function$
;

CREATE OR REPLACE FUNCTION public.geom2d_brin_inclusion_add_value(internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom2d_brin_inclusion_add_value$function$
;

CREATE OR REPLACE FUNCTION public.geom2d_brin_inclusion_merge(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom2d_brin_inclusion_merge$function$
;

CREATE OR REPLACE FUNCTION public.geom3d_brin_inclusion_add_value(internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom3d_brin_inclusion_add_value$function$
;

CREATE OR REPLACE FUNCTION public.geom3d_brin_inclusion_merge(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom3d_brin_inclusion_merge$function$
;

CREATE OR REPLACE FUNCTION public.geom4d_brin_inclusion_add_value(internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom4d_brin_inclusion_add_value$function$
;

CREATE OR REPLACE FUNCTION public.geom4d_brin_inclusion_merge(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$geom4d_brin_inclusion_merge$function$
;

CREATE OR REPLACE FUNCTION public.geometry(geometry, integer, boolean)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_enforce_typmod$function$
;

CREATE OR REPLACE FUNCTION public.geometry(point)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$point_to_geometry$function$
;

CREATE OR REPLACE FUNCTION public.geometry(path)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$path_to_geometry$function$
;

CREATE OR REPLACE FUNCTION public.geometry(polygon)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$polygon_to_geometry$function$
;

CREATE OR REPLACE FUNCTION public.geometry(box2d)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX2D_to_LWGEOM$function$
;

CREATE OR REPLACE FUNCTION public.geometry(box3d)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_to_LWGEOM$function$
;

CREATE OR REPLACE FUNCTION public.geometry(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$parse_WKT_lwgeom$function$
;

CREATE OR REPLACE FUNCTION public.geometry(bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_from_bytea$function$
;

CREATE OR REPLACE FUNCTION public.geometry(geography)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_from_geography$function$
;

CREATE OR REPLACE FUNCTION public.geometry_above(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_above_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_analyze(internal)
 RETURNS boolean
 LANGUAGE c
 STRICT
AS '$libdir/postgis-3', $function$gserialized_analyze_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_below(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_below_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_cmp(geom1 geometry, geom2 geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_cmp$function$
;

CREATE OR REPLACE FUNCTION public.geometry_contained_3d(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contained_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_contains(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_contains_3d(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_contains_nd(geometry, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains$function$
;

CREATE OR REPLACE FUNCTION public.geometry_distance_box(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_distance_box_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_distance_centroid(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_Distance$function$
;

CREATE OR REPLACE FUNCTION public.geometry_distance_centroid_nd(geometry, geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_distance_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_distance_cpa(geometry, geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_DistanceCPA$function$
;

CREATE OR REPLACE FUNCTION public.geometry_eq(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_eq$function$
;

CREATE OR REPLACE FUNCTION public.geometry_ge(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_ge$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_compress_2d(internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_compress_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_compress_nd(internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_compress$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_consistent_2d(internal, geometry, integer)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_consistent_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_consistent_nd(internal, geometry, integer)
 RETURNS boolean
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_consistent$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_decompress_2d(internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_decompress_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_decompress_nd(internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_decompress$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_distance_2d(internal, geometry, integer)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_distance_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_distance_nd(internal, geometry, integer)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_distance$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_penalty_2d(internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_penalty_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_penalty_nd(internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_penalty$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_picksplit_2d(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_picksplit_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_picksplit_nd(internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_picksplit$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_same_2d(geom1 geometry, geom2 geometry, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_same_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_same_nd(geometry, geometry, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_same$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_sortsupport_2d(internal)
 RETURNS void
 LANGUAGE c
 STRICT
AS '$libdir/postgis-3', $function$gserialized_gist_sortsupport_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_union_2d(bytea, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_union_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gist_union_nd(bytea, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_union$function$
;

CREATE OR REPLACE FUNCTION public.geometry_gt(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_gt$function$
;

CREATE OR REPLACE FUNCTION public.geometry_hash(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_hash$function$
;

CREATE OR REPLACE FUNCTION public.geometry_in(cstring)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_in$function$
;

CREATE OR REPLACE FUNCTION public.geometry_le(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_le$function$
;

CREATE OR REPLACE FUNCTION public.geometry_left(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_left_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_lt(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_lt$function$
;

CREATE OR REPLACE FUNCTION public.geometry_neq(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_neq$function$
;

CREATE OR REPLACE FUNCTION public.geometry_out(geometry)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_out$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overabove(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overabove_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overbelow(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overbelow_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overlaps(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overlaps_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overlaps_3d(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overlaps_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overlaps_nd(geometry, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overleft(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overleft_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_overright(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overright_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_recv(internal)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_recv$function$
;

CREATE OR REPLACE FUNCTION public.geometry_right(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_right_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_same(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_same_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_same_3d(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_same_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_same_nd(geometry, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_same$function$
;

CREATE OR REPLACE FUNCTION public.geometry_send(geometry)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_send$function$
;

CREATE OR REPLACE FUNCTION public.geometry_sortsupport(internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$lwgeom_sortsupport$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_choose_2d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_choose_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_choose_3d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_choose_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_choose_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_choose_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_compress_2d(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_compress_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_compress_3d(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_compress_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_compress_nd(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_compress_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_config_2d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_config_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_config_3d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_config_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_config_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_config_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_inner_consistent_2d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_inner_consistent_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_inner_consistent_3d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_inner_consistent_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_inner_consistent_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_inner_consistent_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_leaf_consistent_2d(internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_leaf_consistent_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_leaf_consistent_3d(internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_leaf_consistent_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_leaf_consistent_nd(internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_leaf_consistent_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_picksplit_2d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_picksplit_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_picksplit_3d(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_picksplit_3d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_spgist_picksplit_nd(internal, internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_spgist_picksplit_nd$function$
;

CREATE OR REPLACE FUNCTION public.geometry_typmod_in(cstring[])
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_typmod_in$function$
;

CREATE OR REPLACE FUNCTION public.geometry_typmod_out(integer)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_typmod_out$function$
;

CREATE OR REPLACE FUNCTION public.geometry_within(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_within_2d$function$
;

CREATE OR REPLACE FUNCTION public.geometry_within_nd(geometry, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_within$function$
;

CREATE OR REPLACE FUNCTION public.geometrytype(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_getTYPE$function$
;

CREATE OR REPLACE FUNCTION public.geometrytype(geography)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_getTYPE$function$
;

CREATE OR REPLACE FUNCTION public.geomfromewkb(bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOMFromEWKB$function$
;

CREATE OR REPLACE FUNCTION public.geomfromewkt(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$parse_WKT_lwgeom$function$
;

CREATE OR REPLACE FUNCTION public.get_proj4_from_srid(integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
	BEGIN
	RETURN proj4text::text FROM public.spatial_ref_sys WHERE srid= $1;
	END;
	$function$
;

CREATE OR REPLACE FUNCTION public.gidx_in(cstring)
 RETURNS gidx
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gidx_in$function$
;

CREATE OR REPLACE FUNCTION public.gidx_out(gidx)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gidx_out$function$
;

CREATE OR REPLACE FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_extract_query_trgm$function$
;

CREATE OR REPLACE FUNCTION public.gin_extract_value_trgm(text, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_extract_value_trgm$function$
;

CREATE OR REPLACE FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_trgm_consistent$function$
;

CREATE OR REPLACE FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal)
 RETURNS "char"
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_trgm_triconsistent$function$
;

CREATE OR REPLACE FUNCTION public.gserialized_gist_joinsel_2d(internal, oid, internal, smallint)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_joinsel_2d$function$
;

CREATE OR REPLACE FUNCTION public.gserialized_gist_joinsel_nd(internal, oid, internal, smallint)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_joinsel_nd$function$
;

CREATE OR REPLACE FUNCTION public.gserialized_gist_sel_2d(internal, oid, internal, integer)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_sel_2d$function$
;

CREATE OR REPLACE FUNCTION public.gserialized_gist_sel_nd(internal, oid, internal, integer)
 RETURNS double precision
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/postgis-3', $function$gserialized_gist_sel_nd$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_compress(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_compress$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_consistent$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_decompress(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_decompress$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_distance$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_in(cstring)
 RETURNS gtrgm
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_in$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_options(internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/pg_trgm', $function$gtrgm_options$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_out(gtrgm)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_out$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_penalty(internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_penalty$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_picksplit(internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_picksplit$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_same(gtrgm, gtrgm, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_same$function$
;

CREATE OR REPLACE FUNCTION public.gtrgm_union(internal, internal)
 RETURNS gtrgm
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_union$function$
;

CREATE OR REPLACE FUNCTION public.hmac(text, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_hmac$function$
;

CREATE OR REPLACE FUNCTION public.hmac(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pg_hmac$function$
;

CREATE OR REPLACE FUNCTION public.immutable_unaccent(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
    SELECT public.unaccent($1);
$function$
;

CREATE OR REPLACE FUNCTION public.is_contained_2d(box2df, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_within_box2df_geom_2d$function$
;

CREATE OR REPLACE FUNCTION public.is_contained_2d(box2df, box2df)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_box2df_box2df_2d$function$
;

CREATE OR REPLACE FUNCTION public.is_contained_2d(geometry, box2df)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 1
AS $function$SELECT $2 OPERATOR(public.~) $1;$function$
;

CREATE OR REPLACE FUNCTION public."json"(geometry)
 RETURNS json
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geometry_to_json$function$
;

CREATE OR REPLACE FUNCTION public.jsonb(geometry)
 RETURNS jsonb
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geometry_to_jsonb$function$
;

CREATE OR REPLACE FUNCTION public.log_audit()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (NEW.created_by, TG_OP, TG_TABLE_NAME, NEW.id, now(), to_jsonb(NEW));
        RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (NEW.updated_by, TG_OP, TG_TABLE_NAME, NEW.id, now(), jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW)));
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_logs (user_id, action, record_type, record_id, timestamp, details)
        VALUES (NULL, TG_OP, TG_TABLE_NAME, OLD.id, now(), to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_2d(box2df, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_overlaps_box2df_geom_2d$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_2d(box2df, box2df)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_contains_box2df_box2df_2d$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_2d(geometry, box2df)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 1
AS $function$SELECT $2 OPERATOR(public.&&) $1;$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_geog(gidx, geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/postgis-3', $function$gserialized_gidx_geog_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_geog(gidx, gidx)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/postgis-3', $function$gserialized_gidx_gidx_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_geog(geography, gidx)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$SELECT $2 OPERATOR(public.&&) $1;$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_nd(gidx, geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_gidx_geom_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_nd(gidx, gidx)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$gserialized_gidx_gidx_overlaps$function$
;

CREATE OR REPLACE FUNCTION public.overlaps_nd(geometry, gidx)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 1
AS $function$SELECT $2 OPERATOR(public.&&&) $1;$function$
;

CREATE OR REPLACE FUNCTION public.path(geometry)
 RETURNS path
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_to_path$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asflatgeobuf_finalfn(internal)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asflatgeobuf_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_asflatgeobuf_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_asflatgeobuf_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asflatgeobuf_transfn(internal, anyelement, boolean, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_asflatgeobuf_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asgeobuf_finalfn(internal)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asgeobuf_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_asgeobuf_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asgeobuf_transfn(internal, anyelement, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_asgeobuf_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_combinefn(internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_combinefn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_deserialfn(bytea, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_deserialfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_finalfn(internal)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_serialfn(internal)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_serialfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_transfn(internal, anyelement)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_asmvt_transfn(internal, anyelement, text, integer, text, text)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_asmvt_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_accum_transfn(internal, geometry)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_geometry_accum_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_accum_transfn(internal, geometry, double precision)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_geometry_accum_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_accum_transfn(internal, geometry, double precision, integer)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_geometry_accum_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_clusterintersecting_finalfn(internal)
 RETURNS geometry[]
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_clusterintersecting_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_clusterwithin_finalfn(internal)
 RETURNS geometry[]
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_clusterwithin_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_collect_finalfn(internal)
 RETURNS geometry
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_collect_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_coverageunion_finalfn(internal)
 RETURNS geometry
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_coverageunion_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_makeline_finalfn(internal)
 RETURNS geometry
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_makeline_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_polygonize_finalfn(internal)
 RETURNS geometry
 LANGUAGE c
 PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_geometry_polygonize_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_combinefn(internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_combinefn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_deserialfn(bytea, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_deserialfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_finalfn(internal)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_finalfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_serialfn(internal)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_serialfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_transfn(internal, geometry)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgis_geometry_union_parallel_transfn(internal, geometry, double precision)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$pgis_geometry_union_parallel_transfn$function$
;

CREATE OR REPLACE FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_armor_headers$function$
;

CREATE OR REPLACE FUNCTION public.pgp_key_id(bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_key_id_w$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt(bytea, bytea)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt(bytea, bytea, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_decrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_encrypt(text, bytea)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_encrypt(text, bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_pub_encrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_decrypt(bytea, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_decrypt(bytea, text, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_decrypt_bytea(bytea, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_decrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_encrypt(text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_encrypt(text, text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_text$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_encrypt_bytea(bytea, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text)
 RETURNS bytea
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/pgcrypto', $function$pgp_sym_encrypt_bytea$function$
;

CREATE OR REPLACE FUNCTION public.point(geometry)
 RETURNS point
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_to_point$function$
;

CREATE OR REPLACE FUNCTION public.polygon(geometry)
 RETURNS polygon
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_to_polygon$function$
;

CREATE OR REPLACE FUNCTION public.populate_geometry_columns(use_typmod boolean DEFAULT true)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	inserted	integer;
	oldcount	integer;
	probed	  integer;
	stale	   integer;
	gcs		 RECORD;
	gc		  RECORD;
	gsrid	   integer;
	gndims	  integer;
	gtype	   text;
	query	   text;
	gc_is_valid boolean;

BEGIN
	SELECT count(*) INTO oldcount FROM public.geometry_columns;
	inserted := 0;

	-- Count the number of geometry columns in all tables and views
	SELECT count(DISTINCT c.oid) INTO probed
	FROM pg_class c,
		 pg_attribute a,
		 pg_type t,
		 pg_namespace n
	WHERE c.relkind IN('r','v','f', 'p')
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%' AND c.relname != 'raster_columns' ;

	-- Iterate through all non-dropped geometry columns
	RAISE DEBUG 'Processing Tables.....';

	FOR gcs IN
	SELECT DISTINCT ON (c.oid) c.oid, n.nspname, c.relname
		FROM pg_class c,
			 pg_attribute a,
			 pg_type t,
			 pg_namespace n
		WHERE c.relkind IN( 'r', 'f', 'p')
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%' AND c.relname != 'raster_columns'
	LOOP

		inserted := inserted + public.populate_geometry_columns(gcs.oid, use_typmod);
	END LOOP;

	IF oldcount > inserted THEN
		stale = oldcount-inserted;
	ELSE
		stale = 0;
	END IF;

	RETURN 'probed:' ||probed|| ' inserted:'||inserted;
END

$function$
;

CREATE OR REPLACE FUNCTION public.populate_geometry_columns(tbl_oid oid, use_typmod boolean DEFAULT true)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
	gcs		 RECORD;
	gc		  RECORD;
	gc_old	  RECORD;
	gsrid	   integer;
	gndims	  integer;
	gtype	   text;
	query	   text;
	gc_is_valid boolean;
	inserted	integer;
	constraint_successful boolean := false;

BEGIN
	inserted := 0;

	-- Iterate through all geometry columns in this table
	FOR gcs IN
	SELECT n.nspname, c.relname, a.attname, c.relkind
		FROM pg_class c,
			 pg_attribute a,
			 pg_type t,
			 pg_namespace n
		WHERE c.relkind IN('r', 'f', 'p')
		AND t.typname = 'geometry'
		AND a.attisdropped = false
		AND a.atttypid = t.oid
		AND a.attrelid = c.oid
		AND c.relnamespace = n.oid
		AND n.nspname NOT ILIKE 'pg_temp%'
		AND c.oid = tbl_oid
	LOOP

		RAISE DEBUG 'Processing column %.%.%', gcs.nspname, gcs.relname, gcs.attname;

		gc_is_valid := true;
		-- Find the srid, coord_dimension, and type of current geometry
		-- in geometry_columns -- which is now a view

		SELECT type, srid, coord_dimension, gcs.relkind INTO gc_old
			FROM geometry_columns
			WHERE f_table_schema = gcs.nspname AND f_table_name = gcs.relname AND f_geometry_column = gcs.attname;

		IF upper(gc_old.type) = 'GEOMETRY' THEN
		-- This is an unconstrained geometry we need to do something
		-- We need to figure out what to set the type by inspecting the data
			EXECUTE 'SELECT public.ST_srid(' || quote_ident(gcs.attname) || ') As srid, public.GeometryType(' || quote_ident(gcs.attname) || ') As type, public.ST_NDims(' || quote_ident(gcs.attname) || ') As dims ' ||
					 ' FROM ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) ||
					 ' WHERE ' || quote_ident(gcs.attname) || ' IS NOT NULL LIMIT 1;'
				INTO gc;
			IF gc IS NULL THEN -- there is no data so we can not determine geometry type
				RAISE WARNING 'No data in table %.%, so no information to determine geometry type and srid', gcs.nspname, gcs.relname;
				RETURN 0;
			END IF;
			gsrid := gc.srid; gtype := gc.type; gndims := gc.dims;

			IF use_typmod THEN
				BEGIN
					EXECUTE 'ALTER TABLE ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || ' ALTER COLUMN ' || quote_ident(gcs.attname) ||
						' TYPE geometry(' || postgis_type_name(gtype, gndims, true) || ', ' || gsrid::text  || ') ';
					inserted := inserted + 1;
				EXCEPTION
						WHEN invalid_parameter_value OR feature_not_supported THEN
						RAISE WARNING 'Could not convert ''%'' in ''%.%'' to use typmod with srid %, type %: %', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), gsrid, postgis_type_name(gtype, gndims, true), SQLERRM;
							gc_is_valid := false;
				END;

			ELSE
				-- Try to apply srid check to column
				constraint_successful = false;
				IF (gsrid > 0 AND postgis_constraint_srid(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
					BEGIN
						EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) ||
								 ' ADD CONSTRAINT ' || quote_ident('enforce_srid_' || gcs.attname) ||
								 ' CHECK (ST_srid(' || quote_ident(gcs.attname) || ') = ' || gsrid || ')';
						constraint_successful := true;
					EXCEPTION
						WHEN check_violation THEN
							RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (st_srid(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gsrid;
							gc_is_valid := false;
					END;
				END IF;

				-- Try to apply ndims check to column
				IF (gndims IS NOT NULL AND postgis_constraint_dims(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
					BEGIN
						EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || '
								 ADD CONSTRAINT ' || quote_ident('enforce_dims_' || gcs.attname) || '
								 CHECK (st_ndims(' || quote_ident(gcs.attname) || ') = '||gndims||')';
						constraint_successful := true;
					EXCEPTION
						WHEN check_violation THEN
							RAISE WARNING 'Not inserting ''%'' in ''%.%'' into geometry_columns: could not apply constraint CHECK (st_ndims(%) = %)', quote_ident(gcs.attname), quote_ident(gcs.nspname), quote_ident(gcs.relname), quote_ident(gcs.attname), gndims;
							gc_is_valid := false;
					END;
				END IF;

				-- Try to apply geometrytype check to column
				IF (gtype IS NOT NULL AND postgis_constraint_type(gcs.nspname, gcs.relname,gcs.attname) IS NULL ) THEN
					BEGIN
						EXECUTE 'ALTER TABLE ONLY ' || quote_ident(gcs.nspname) || '.' || quote_ident(gcs.relname) || '
						ADD CONSTRAINT ' || quote_ident('enforce_geotype_' || gcs.attname) || '
						CHECK (geometrytype(' || quote_ident(gcs.attname) || ') = ' || quote_literal(gtype) || ')';
						constraint_successful := true;
					EXCEPTION
						WHEN check_violation THEN
							-- No geometry check can be applied. This column contains a number of geometry types.
							RAISE WARNING 'Could not add geometry type check (%) to table column: %.%.%', gtype, quote_ident(gcs.nspname),quote_ident(gcs.relname),quote_ident(gcs.attname);
					END;
				END IF;
				 --only count if we were successful in applying at least one constraint
				IF constraint_successful THEN
					inserted := inserted + 1;
				END IF;
			END IF;
		END IF;

	END LOOP;

	RETURN inserted;
END

$function$
;

CREATE OR REPLACE FUNCTION public.postgis_addbbox(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_addBBOX$function$
;

CREATE OR REPLACE FUNCTION public.postgis_cache_bbox()
 RETURNS trigger
 LANGUAGE c
AS '$libdir/postgis-3', $function$cache_bbox$function$
;

CREATE OR REPLACE FUNCTION public.postgis_constraint_dims(geomschema text, geomtable text, geomcolumn text)
 RETURNS integer
 LANGUAGE sql
 STABLE PARALLEL SAFE STRICT COST 250
AS $function$
SELECT  replace(split_part(s.consrc, ' = ', 2), ')', '')::integer
		 FROM pg_class c, pg_namespace n, pg_attribute a
		 , (SELECT connamespace, conrelid, conkey, pg_get_constraintdef(oid) As consrc
			FROM pg_constraint) AS s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%ndims(% = %';
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_constraint_srid(geomschema text, geomtable text, geomcolumn text)
 RETURNS integer
 LANGUAGE sql
 STABLE PARALLEL SAFE STRICT COST 250
AS $function$
SELECT replace(replace(split_part(s.consrc, ' = ', 2), ')', ''), '(', '')::integer
		 FROM pg_class c, pg_namespace n, pg_attribute a
		 , (SELECT connamespace, conrelid, conkey, pg_get_constraintdef(oid) As consrc
			FROM pg_constraint) AS s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%srid(% = %';
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_constraint_type(geomschema text, geomtable text, geomcolumn text)
 RETURNS character varying
 LANGUAGE sql
 STABLE PARALLEL SAFE STRICT COST 250
AS $function$
SELECT  replace(split_part(s.consrc, '''', 2), ')', '')::varchar
		 FROM pg_class c, pg_namespace n, pg_attribute a
		 , (SELECT connamespace, conrelid, conkey, pg_get_constraintdef(oid) As consrc
			FROM pg_constraint) AS s
		 WHERE n.nspname = $1
		 AND c.relname = $2
		 AND a.attname = $3
		 AND a.attrelid = c.oid
		 AND s.connamespace = n.oid
		 AND s.conrelid = c.oid
		 AND a.attnum = ANY (s.conkey)
		 AND s.consrc LIKE '%geometrytype(% = %';
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_dropbbox(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_dropBBOX$function$
;

CREATE OR REPLACE FUNCTION public.postgis_extensions_upgrade(target_version text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
	rec record;
	sql text;
	var_schema text;
BEGIN

	FOR rec IN
		SELECT name, default_version, installed_version
		FROM pg_catalog.pg_available_extensions
		WHERE name IN (
			'postgis',
			'postgis_raster',
			'postgis_sfcgal',
			'postgis_topology',
			'postgis_tiger_geocoder'
		)
		ORDER BY length(name) -- this is to make sure 'postgis' is first !
	LOOP --{

		IF target_version IS NULL THEN
			target_version := rec.default_version;
		END IF;

		IF rec.installed_version IS NULL THEN --{
			-- If the support installed by available extension
			-- is found unpackaged, we package it
			IF --{
				 -- PostGIS is always available (this function is part of it)
				 rec.name = 'postgis'

				 -- PostGIS raster is available if type 'raster' exists
				 OR ( rec.name = 'postgis_raster' AND EXISTS (
							SELECT 1 FROM pg_catalog.pg_type
							WHERE typname = 'raster' ) )

				 -- PostGIS SFCGAL is available if
				 -- 'postgis_sfcgal_version' function exists
				 OR ( rec.name = 'postgis_sfcgal' AND EXISTS (
							SELECT 1 FROM pg_catalog.pg_proc
							WHERE proname = 'postgis_sfcgal_version' ) )

				 -- PostGIS Topology is available if
				 -- 'topology.topology' table exists
				 -- NOTE: watch out for https://trac.osgeo.org/postgis/ticket/2503
				 OR ( rec.name = 'postgis_topology' AND EXISTS (
							SELECT 1 FROM pg_catalog.pg_class c
							JOIN pg_catalog.pg_namespace n ON (c.relnamespace = n.oid )
							WHERE n.nspname = 'topology' AND c.relname = 'topology') )

				 OR ( rec.name = 'postgis_tiger_geocoder' AND EXISTS (
							SELECT 1 FROM pg_catalog.pg_class c
							JOIN pg_catalog.pg_namespace n ON (c.relnamespace = n.oid )
							WHERE n.nspname = 'tiger' AND c.relname = 'geocode_settings') )
			THEN --}{ -- the code is unpackaged
				-- Force install in same schema as postgis
				SELECT INTO var_schema n.nspname
				  FROM pg_namespace n, pg_proc p
				  WHERE p.proname = 'postgis_full_version'
					AND n.oid = p.pronamespace
				  LIMIT 1;
				IF rec.name NOT IN('postgis_topology', 'postgis_tiger_geocoder')
				THEN
					sql := format(
							  'CREATE EXTENSION %1$I SCHEMA %2$I VERSION unpackaged;'
							  'ALTER EXTENSION %1$I UPDATE TO %3$I',
							  rec.name, var_schema, target_version);
				ELSE
					sql := format(
							 'CREATE EXTENSION %1$I VERSION unpackaged;'
							 'ALTER EXTENSION %1$I UPDATE TO %2$I',
							 rec.name, target_version);
				END IF;
				RAISE NOTICE 'Packaging and updating %', rec.name;
				RAISE DEBUG '%', sql;
				EXECUTE sql;
			ELSE
				RAISE DEBUG 'Skipping % (not in use)', rec.name;
			END IF; --}
		ELSE -- The code is already packaged, upgrade it --}{
			sql = format(
				'ALTER EXTENSION %1$I UPDATE TO "ANY";'
				'ALTER EXTENSION %1$I UPDATE TO %2$I',
				rec.name, target_version
				);
			RAISE NOTICE 'Updating extension % %', rec.name, rec.installed_version;
			RAISE DEBUG '%', sql;
			EXECUTE sql;
		END IF; --}

	END LOOP; --}

	RETURN format(
		'Upgrade to version %s completed, run SELECT postgis_full_version(); for details',
		target_version
	);


END
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_full_version()
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
	libver text;
	librev text;
	projver text;
	projver_compiled text;
	geosver text;
	geosver_compiled text;
	sfcgalver text;
	gdalver text := NULL;
	libxmlver text;
	liblwgeomver text;
	dbproc text;
	relproc text;
	fullver text;
	rast_lib_ver text := NULL;
	rast_scr_ver text := NULL;
	topo_scr_ver text := NULL;
	json_lib_ver text;
	protobuf_lib_ver text;
	wagyu_lib_ver text;
	sfcgal_lib_ver text;
	sfcgal_scr_ver text;
	pgsql_scr_ver text;
	pgsql_ver text;
	core_is_extension bool;
BEGIN
	SELECT public.postgis_lib_version() INTO libver;
	SELECT public.postgis_proj_version() INTO projver;
	SELECT public.postgis_geos_version() INTO geosver;
	SELECT public.postgis_geos_compiled_version() INTO geosver_compiled;
	SELECT public.postgis_proj_compiled_version() INTO projver_compiled;
	SELECT public.postgis_libjson_version() INTO json_lib_ver;
	SELECT public.postgis_libprotobuf_version() INTO protobuf_lib_ver;
	SELECT public.postgis_wagyu_version() INTO wagyu_lib_ver;
	SELECT public._postgis_scripts_pgsql_version() INTO pgsql_scr_ver;
	SELECT public._postgis_pgsql_version() INTO pgsql_ver;
	BEGIN
		SELECT public.postgis_gdal_version() INTO gdalver;
	EXCEPTION
		WHEN undefined_function THEN
			RAISE DEBUG 'Function postgis_gdal_version() not found.  Is raster support enabled and rtpostgis.sql installed?';
	END;
	BEGIN
		SELECT public.postgis_sfcgal_full_version() INTO sfcgalver;
		BEGIN
			SELECT public.postgis_sfcgal_scripts_installed() INTO sfcgal_scr_ver;
		EXCEPTION
			WHEN undefined_function THEN
				sfcgal_scr_ver := 'missing';
		END;
	EXCEPTION
		WHEN undefined_function THEN
			RAISE DEBUG 'Function postgis_sfcgal_scripts_installed() not found. Is sfcgal support enabled and sfcgal.sql installed?';
	END;
	SELECT public.postgis_liblwgeom_version() INTO liblwgeomver;
	SELECT public.postgis_libxml_version() INTO libxmlver;
	SELECT public.postgis_scripts_installed() INTO dbproc;
	SELECT public.postgis_scripts_released() INTO relproc;
	SELECT public.postgis_lib_revision() INTO librev;
	BEGIN
		SELECT topology.postgis_topology_scripts_installed() INTO topo_scr_ver;
	EXCEPTION
		WHEN undefined_function OR invalid_schema_name THEN
			RAISE DEBUG 'Function postgis_topology_scripts_installed() not found. Is topology support enabled and topology.sql installed?';
		WHEN insufficient_privilege THEN
			RAISE NOTICE 'Topology support cannot be inspected. Is current user granted USAGE on schema "topology" ?';
		WHEN OTHERS THEN
			RAISE NOTICE 'Function postgis_topology_scripts_installed() could not be called: % (%)', SQLERRM, SQLSTATE;
	END;

	BEGIN
		SELECT postgis_raster_scripts_installed() INTO rast_scr_ver;
	EXCEPTION
		WHEN undefined_function THEN
			RAISE DEBUG 'Function postgis_raster_scripts_installed() not found. Is raster support enabled and rtpostgis.sql installed?';
		WHEN OTHERS THEN
			RAISE NOTICE 'Function postgis_raster_scripts_installed() could not be called: % (%)', SQLERRM, SQLSTATE;
	END;

	BEGIN
		SELECT public.postgis_raster_lib_version() INTO rast_lib_ver;
	EXCEPTION
		WHEN undefined_function THEN
			RAISE DEBUG 'Function postgis_raster_lib_version() not found. Is raster support enabled and rtpostgis.sql installed?';
		WHEN OTHERS THEN
			RAISE NOTICE 'Function postgis_raster_lib_version() could not be called: % (%)', SQLERRM, SQLSTATE;
	END;

	fullver = 'POSTGIS="' || libver;

	IF  librev IS NOT NULL THEN
		fullver = fullver || ' ' || librev;
	END IF;

	fullver = fullver || '"';

	IF EXISTS (
		SELECT * FROM pg_catalog.pg_extension
		WHERE extname = 'postgis')
	THEN
			fullver = fullver || ' [EXTENSION]';
			core_is_extension := true;
	ELSE
			core_is_extension := false;
	END IF;

	IF liblwgeomver != relproc THEN
		fullver = fullver || ' (liblwgeom version mismatch: "' || liblwgeomver || '")';
	END IF;

	fullver = fullver || ' PGSQL="' || pgsql_scr_ver || '"';
	IF pgsql_scr_ver != pgsql_ver THEN
		fullver = fullver || ' (procs need upgrade for use with PostgreSQL "' || pgsql_ver || '")';
	END IF;

	IF  geosver IS NOT NULL THEN
		fullver = fullver || ' GEOS="' || geosver || '"';
		IF (string_to_array(geosver, '.'))[1:2] != (string_to_array(geosver_compiled, '.'))[1:2]
		THEN
			fullver = format('%s (compiled against GEOS %s)', fullver, geosver_compiled);
		END IF;
	END IF;

	IF  sfcgalver IS NOT NULL THEN
		fullver = fullver || ' SFCGAL="' || sfcgalver || '"';
	END IF;

	IF  projver IS NOT NULL THEN
		fullver = fullver || ' PROJ="' || projver || '"';
		IF (string_to_array(projver, '.'))[1:3] != (string_to_array(projver_compiled, '.'))[1:3]
		THEN
			fullver = format('%s (compiled against PROJ %s)', fullver, projver_compiled);
		END IF;
	END IF;

	IF  gdalver IS NOT NULL THEN
		fullver = fullver || ' GDAL="' || gdalver || '"';
	END IF;

	IF  libxmlver IS NOT NULL THEN
		fullver = fullver || ' LIBXML="' || libxmlver || '"';
	END IF;

	IF json_lib_ver IS NOT NULL THEN
		fullver = fullver || ' LIBJSON="' || json_lib_ver || '"';
	END IF;

	IF protobuf_lib_ver IS NOT NULL THEN
		fullver = fullver || ' LIBPROTOBUF="' || protobuf_lib_ver || '"';
	END IF;

	IF wagyu_lib_ver IS NOT NULL THEN
		fullver = fullver || ' WAGYU="' || wagyu_lib_ver || '"';
	END IF;

	IF dbproc != relproc THEN
		fullver = fullver || ' (core procs from "' || dbproc || '" need upgrade)';
	END IF;

	IF topo_scr_ver IS NOT NULL THEN
		fullver = fullver || ' TOPOLOGY';
		IF topo_scr_ver != relproc THEN
			fullver = fullver || ' (topology procs from "' || topo_scr_ver || '" need upgrade)';
		END IF;
		IF core_is_extension AND NOT EXISTS (
			SELECT * FROM pg_catalog.pg_extension
			WHERE extname = 'postgis_topology')
		THEN
				fullver = fullver || ' [UNPACKAGED!]';
		END IF;
	END IF;

	IF rast_lib_ver IS NOT NULL THEN
		fullver = fullver || ' RASTER';
		IF rast_lib_ver != relproc THEN
			fullver = fullver || ' (raster lib from "' || rast_lib_ver || '" need upgrade)';
		END IF;
		IF core_is_extension AND NOT EXISTS (
			SELECT * FROM pg_catalog.pg_extension
			WHERE extname = 'postgis_raster')
		THEN
				fullver = fullver || ' [UNPACKAGED!]';
		END IF;
	END IF;

	IF rast_scr_ver IS NOT NULL AND rast_scr_ver != relproc THEN
		fullver = fullver || ' (raster procs from "' || rast_scr_ver || '" need upgrade)';
	END IF;

	IF sfcgal_scr_ver IS NOT NULL AND sfcgal_scr_ver != relproc THEN
		fullver = fullver || ' (sfcgal procs from "' || sfcgal_scr_ver || '" need upgrade)';
	END IF;

	-- Check for the presence of deprecated functions
	IF EXISTS ( SELECT oid FROM pg_catalog.pg_proc WHERE proname LIKE '%_deprecated_by_postgis_%' )
	THEN
		fullver = fullver || ' (deprecated functions exist, upgrade is not complete)';
	END IF;

	RETURN fullver;
END
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_geos_compiled_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_geos_compiled_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_geos_noop(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$GEOSnoop$function$
;

CREATE OR REPLACE FUNCTION public.postgis_geos_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_geos_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_getbbox(geometry)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_to_BOX2DF$function$
;

CREATE OR REPLACE FUNCTION public.postgis_hasbbox(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_hasBBOX$function$
;

CREATE OR REPLACE FUNCTION public.postgis_index_supportfn(internal)
 RETURNS internal
 LANGUAGE c
AS '$libdir/postgis-3', $function$postgis_index_supportfn$function$
;

CREATE OR REPLACE FUNCTION public.postgis_lib_build_date()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_lib_build_date$function$
;

CREATE OR REPLACE FUNCTION public.postgis_lib_revision()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_lib_revision$function$
;

CREATE OR REPLACE FUNCTION public.postgis_lib_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_lib_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_libjson_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_libjson_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_liblwgeom_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_liblwgeom_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_libprotobuf_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE STRICT
AS '$libdir/postgis-3', $function$postgis_libprotobuf_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_libxml_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_libxml_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_noop(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_noop$function$
;

CREATE OR REPLACE FUNCTION public.postgis_proj_compiled_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_proj_compiled_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_proj_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_proj_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_scripts_build_date()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$SELECT '2025-09-02 07:35:26'::text AS version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_scripts_installed()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$ SELECT trim('3.6.0'::text || $rev$ 4c1967d $rev$) AS version $function$
;

CREATE OR REPLACE FUNCTION public.postgis_scripts_released()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_scripts_released$function$
;

CREATE OR REPLACE FUNCTION public.postgis_srs(auth_name text, auth_srid text)
 RETURNS TABLE(auth_name text, auth_srid text, srname text, srtext text, proj4text text, point_sw geometry, point_ne geometry)
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$postgis_srs_entry$function$
;

CREATE OR REPLACE FUNCTION public.postgis_srs_all()
 RETURNS TABLE(auth_name text, auth_srid text, srname text, srtext text, proj4text text, point_sw geometry, point_ne geometry)
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$postgis_srs_entry_all$function$
;

CREATE OR REPLACE FUNCTION public.postgis_srs_codes(auth_name text)
 RETURNS SETOF text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$postgis_srs_codes$function$
;

CREATE OR REPLACE FUNCTION public.postgis_srs_search(bounds geometry, authname text DEFAULT 'EPSG'::text)
 RETURNS TABLE(auth_name text, auth_srid text, srname text, srtext text, proj4text text, point_sw geometry, point_ne geometry)
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$postgis_srs_search$function$
;

CREATE OR REPLACE FUNCTION public.postgis_svn_version()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
	SELECT public._postgis_deprecate(
		'postgis_svn_version', 'postgis_lib_revision', '3.1.0');
	SELECT public.postgis_lib_revision();
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_transform_geometry(geom geometry, text, text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$transform_geom$function$
;

CREATE OR REPLACE FUNCTION public.postgis_transform_pipeline_geometry(geom geometry, pipeline text, forward boolean, to_srid integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$transform_pipeline_geom$function$
;

CREATE OR REPLACE FUNCTION public.postgis_type_name(geomname character varying, coord_dimension integer, use_new_name boolean DEFAULT true)
 RETURNS character varying
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$
	SELECT CASE WHEN $3 THEN new_name ELSE old_name END As geomname
	FROM
	( VALUES
			('GEOMETRY', 'Geometry', 2),
			('GEOMETRY', 'GeometryZ', 3),
			('GEOMETRYM', 'GeometryM', 3),
			('GEOMETRY', 'GeometryZM', 4),

			('GEOMETRYCOLLECTION', 'GeometryCollection', 2),
			('GEOMETRYCOLLECTION', 'GeometryCollectionZ', 3),
			('GEOMETRYCOLLECTIONM', 'GeometryCollectionM', 3),
			('GEOMETRYCOLLECTION', 'GeometryCollectionZM', 4),

			('POINT', 'Point', 2),
			('POINT', 'PointZ', 3),
			('POINTM','PointM', 3),
			('POINT', 'PointZM', 4),

			('MULTIPOINT','MultiPoint', 2),
			('MULTIPOINT','MultiPointZ', 3),
			('MULTIPOINTM','MultiPointM', 3),
			('MULTIPOINT','MultiPointZM', 4),

			('POLYGON', 'Polygon', 2),
			('POLYGON', 'PolygonZ', 3),
			('POLYGONM', 'PolygonM', 3),
			('POLYGON', 'PolygonZM', 4),

			('MULTIPOLYGON', 'MultiPolygon', 2),
			('MULTIPOLYGON', 'MultiPolygonZ', 3),
			('MULTIPOLYGONM', 'MultiPolygonM', 3),
			('MULTIPOLYGON', 'MultiPolygonZM', 4),

			('MULTILINESTRING', 'MultiLineString', 2),
			('MULTILINESTRING', 'MultiLineStringZ', 3),
			('MULTILINESTRINGM', 'MultiLineStringM', 3),
			('MULTILINESTRING', 'MultiLineStringZM', 4),

			('LINESTRING', 'LineString', 2),
			('LINESTRING', 'LineStringZ', 3),
			('LINESTRINGM', 'LineStringM', 3),
			('LINESTRING', 'LineStringZM', 4),

			('CIRCULARSTRING', 'CircularString', 2),
			('CIRCULARSTRING', 'CircularStringZ', 3),
			('CIRCULARSTRINGM', 'CircularStringM' ,3),
			('CIRCULARSTRING', 'CircularStringZM', 4),

			('COMPOUNDCURVE', 'CompoundCurve', 2),
			('COMPOUNDCURVE', 'CompoundCurveZ', 3),
			('COMPOUNDCURVEM', 'CompoundCurveM', 3),
			('COMPOUNDCURVE', 'CompoundCurveZM', 4),

			('CURVEPOLYGON', 'CurvePolygon', 2),
			('CURVEPOLYGON', 'CurvePolygonZ', 3),
			('CURVEPOLYGONM', 'CurvePolygonM', 3),
			('CURVEPOLYGON', 'CurvePolygonZM', 4),

			('MULTICURVE', 'MultiCurve', 2),
			('MULTICURVE', 'MultiCurveZ', 3),
			('MULTICURVEM', 'MultiCurveM', 3),
			('MULTICURVE', 'MultiCurveZM', 4),

			('MULTISURFACE', 'MultiSurface', 2),
			('MULTISURFACE', 'MultiSurfaceZ', 3),
			('MULTISURFACEM', 'MultiSurfaceM', 3),
			('MULTISURFACE', 'MultiSurfaceZM', 4),

			('POLYHEDRALSURFACE', 'PolyhedralSurface', 2),
			('POLYHEDRALSURFACE', 'PolyhedralSurfaceZ', 3),
			('POLYHEDRALSURFACEM', 'PolyhedralSurfaceM', 3),
			('POLYHEDRALSURFACE', 'PolyhedralSurfaceZM', 4),

			('TRIANGLE', 'Triangle', 2),
			('TRIANGLE', 'TriangleZ', 3),
			('TRIANGLEM', 'TriangleM', 3),
			('TRIANGLE', 'TriangleZM', 4),

			('TIN', 'Tin', 2),
			('TIN', 'TinZ', 3),
			('TINM', 'TinM', 3),
			('TIN', 'TinZM', 4) )
			 As g(old_name, new_name, coord_dimension)
	WHERE (upper(old_name) = upper($1) OR upper(new_name) = upper($1))
		AND coord_dimension = $2;
$function$
;

CREATE OR REPLACE FUNCTION public.postgis_typmod_dims(integer)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_typmod_dims$function$
;

CREATE OR REPLACE FUNCTION public.postgis_typmod_srid(integer)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_typmod_srid$function$
;

CREATE OR REPLACE FUNCTION public.postgis_typmod_type(integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$postgis_typmod_type$function$
;

CREATE OR REPLACE FUNCTION public.postgis_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_version$function$
;

CREATE OR REPLACE FUNCTION public.postgis_wagyu_version()
 RETURNS text
 LANGUAGE c
 IMMUTABLE
AS '$libdir/postgis-3', $function$postgis_wagyu_version$function$
;

CREATE OR REPLACE FUNCTION public.refresh_mv_crm_template_suggestions()
 RETURNS void
 LANGUAGE sql
AS $function$
  REFRESH MATERIALIZED VIEW CONCURRENTLY mv_crm_template_suggestions;
$function$
;

CREATE OR REPLACE FUNCTION public.resolve_sync_conflict()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (NEW.timestamp IS NOT NULL AND EXISTS (
        SELECT 1 FROM diaries d
        WHERE d.id = NEW.id AND d.timestamp > NEW.timestamp
    )) THEN
        RAISE EXCEPTION 'Conflict detected: Newer timestamp exists for diary ID %', NEW.id;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_limit(real)
 RETURNS real
 LANGUAGE c
 STRICT
AS '$libdir/pg_trgm', $function$set_limit$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.show_limit()
 RETURNS real
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$show_limit$function$
;

CREATE OR REPLACE FUNCTION public.show_trgm(text)
 RETURNS text[]
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$show_trgm$function$
;

CREATE OR REPLACE FUNCTION public.similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity$function$
;

CREATE OR REPLACE FUNCTION public.similarity_dist(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity_dist$function$
;

CREATE OR REPLACE FUNCTION public.similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity_op$function$
;

CREATE OR REPLACE FUNCTION public.spheroid_in(cstring)
 RETURNS spheroid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$ellipsoid_in$function$
;

CREATE OR REPLACE FUNCTION public.spheroid_out(spheroid)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$ellipsoid_out$function$
;

CREATE OR REPLACE FUNCTION public.st_3dclosestpoint(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_closestpoint3d$function$
;

CREATE OR REPLACE FUNCTION public.st_3ddfullywithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$LWGEOM_dfullywithin3d$function$
;

CREATE OR REPLACE FUNCTION public.st_3ddistance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_3DDistance$function$
;

CREATE OR REPLACE FUNCTION public.st_3ddwithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$LWGEOM_dwithin3d$function$
;

CREATE OR REPLACE FUNCTION public.st_3dintersects(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$ST_3DIntersects$function$
;

CREATE OR REPLACE FUNCTION public.st_3dlength(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_length_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_3dlineinterpolatepoint(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_3DLineInterpolatePoint$function$
;

CREATE OR REPLACE FUNCTION public.st_3dlongestline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_longestline3d$function$
;

CREATE OR REPLACE FUNCTION public.st_3dmakebox(geom1 geometry, geom2 geometry)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_construct$function$
;

CREATE OR REPLACE FUNCTION public.st_3dmaxdistance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_maxdistance3d$function$
;

CREATE OR REPLACE FUNCTION public.st_3dperimeter(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_perimeter_poly$function$
;

CREATE OR REPLACE FUNCTION public.st_3dshortestline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_shortestline3d$function$
;

CREATE OR REPLACE FUNCTION public.st_addmeasure(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_AddMeasure$function$
;

CREATE OR REPLACE FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_addpoint$function$
;

CREATE OR REPLACE FUNCTION public.st_addpoint(geom1 geometry, geom2 geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_addpoint$function$
;

CREATE OR REPLACE FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_affine$function$
;

CREATE OR REPLACE FUNCTION public.st_affine(geometry, double precision, double precision, double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  $2, $3, 0,  $4, $5, 0,  0, 0, 1,  $6, $7, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_angle(pt1 geometry, pt2 geometry, pt3 geometry, pt4 geometry DEFAULT '0101000000000000000000F87F000000000000F87F'::geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_angle$function$
;

CREATE OR REPLACE FUNCTION public.st_angle(line1 geometry, line2 geometry)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Angle(public.St_StartPoint($1), public.ST_EndPoint($1), public.ST_StartPoint($2), public.ST_EndPoint($2))$function$
;

CREATE OR REPLACE FUNCTION public.st_area(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Area$function$
;

CREATE OR REPLACE FUNCTION public.st_area(geog geography, use_spheroid boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_area$function$
;

CREATE OR REPLACE FUNCTION public.st_area(text)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Area($1::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_area2d(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Area$function$
;

CREATE OR REPLACE FUNCTION public.st_asbinary(geometry, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asBinary$function$
;

CREATE OR REPLACE FUNCTION public.st_asbinary(geometry)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asBinary$function$
;

CREATE OR REPLACE FUNCTION public.st_asbinary(geography)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asBinary$function$
;

CREATE OR REPLACE FUNCTION public.st_asbinary(geography, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asBinary$function$
;

CREATE OR REPLACE FUNCTION public.st_asencodedpolyline(geom geometry, nprecision integer DEFAULT 5)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asEncodedPolyline$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkb(geometry)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$WKBFromLWGEOM$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkb(geometry, text)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$WKBFromLWGEOM$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkt(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asEWKT$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkt(geometry, integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asEWKT$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkt(geography)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asEWKT$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkt(geography, integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asEWKT$function$
;

CREATE OR REPLACE FUNCTION public.st_asewkt(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public.ST_AsEWKT($1::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_asgeojson(geom geometry, maxdecimaldigits integer DEFAULT 9, options integer DEFAULT 8)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asGeoJson$function$
;

CREATE OR REPLACE FUNCTION public.st_asgeojson(r record, geom_column text DEFAULT ''::text, maxdecimaldigits integer DEFAULT 9, pretty_bool boolean DEFAULT false, id_column text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_AsGeoJsonRow$function$
;

CREATE OR REPLACE FUNCTION public.st_asgeojson(geog geography, maxdecimaldigits integer DEFAULT 9, options integer DEFAULT 0)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_as_geojson$function$
;

CREATE OR REPLACE FUNCTION public.st_asgeojson(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public.ST_AsGeoJson($1::public.geometry, 9, 0);  $function$
;

CREATE OR REPLACE FUNCTION public.st_asgml(geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asGML$function$
;

CREATE OR REPLACE FUNCTION public.st_asgml(version integer, geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0, nprefix text DEFAULT NULL::text, id text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asGML$function$
;

CREATE OR REPLACE FUNCTION public.st_asgml(version integer, geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0, nprefix text DEFAULT 'gml'::text, id text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_as_gml$function$
;

CREATE OR REPLACE FUNCTION public.st_asgml(geog geography, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0, nprefix text DEFAULT 'gml'::text, id text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_as_gml$function$
;

CREATE OR REPLACE FUNCTION public.st_asgml(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public._ST_AsGML(2,$1::public.geometry,15,0, NULL, NULL);  $function$
;

CREATE OR REPLACE FUNCTION public.st_ashexewkb(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asHEXEWKB$function$
;

CREATE OR REPLACE FUNCTION public.st_ashexewkb(geometry, text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_asHEXEWKB$function$
;

CREATE OR REPLACE FUNCTION public.st_askml(geom geometry, maxdecimaldigits integer DEFAULT 15, nprefix text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asKML$function$
;

CREATE OR REPLACE FUNCTION public.st_askml(geog geography, maxdecimaldigits integer DEFAULT 15, nprefix text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_as_kml$function$
;

CREATE OR REPLACE FUNCTION public.st_askml(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public.ST_AsKML($1::public.geometry, 15);  $function$
;

CREATE OR REPLACE FUNCTION public.st_aslatlontext(geom geometry, tmpl text DEFAULT ''::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_latlon$function$
;

CREATE OR REPLACE FUNCTION public.st_asmarc21(geom geometry, format text DEFAULT 'hdddmmss'::text)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_AsMARC21$function$
;

CREATE OR REPLACE FUNCTION public.st_asmvtgeom(geom geometry, bounds box2d, extent integer DEFAULT 4096, buffer integer DEFAULT 256, clip_geom boolean DEFAULT true)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$ST_AsMVTGeom$function$
;

CREATE OR REPLACE FUNCTION public.st_assvg(geom geometry, rel integer DEFAULT 0, maxdecimaldigits integer DEFAULT 15)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asSVG$function$
;

CREATE OR REPLACE FUNCTION public.st_assvg(geog geography, rel integer DEFAULT 0, maxdecimaldigits integer DEFAULT 15)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_as_svg$function$
;

CREATE OR REPLACE FUNCTION public.st_assvg(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public.ST_AsSVG($1::public.geometry,0,15);  $function$
;

CREATE OR REPLACE FUNCTION public.st_astext(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asText$function$
;

CREATE OR REPLACE FUNCTION public.st_astext(geometry, integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asText$function$
;

CREATE OR REPLACE FUNCTION public.st_astext(geography)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asText$function$
;

CREATE OR REPLACE FUNCTION public.st_astext(geography, integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_asText$function$
;

CREATE OR REPLACE FUNCTION public.st_astext(text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$ SELECT public.ST_AsText($1::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_astwkb(geom geometry, prec integer DEFAULT NULL::integer, prec_z integer DEFAULT NULL::integer, prec_m integer DEFAULT NULL::integer, with_sizes boolean DEFAULT NULL::boolean, with_boxes boolean DEFAULT NULL::boolean)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$TWKBFromLWGEOM$function$
;

CREATE OR REPLACE FUNCTION public.st_astwkb(geom geometry[], ids bigint[], prec integer DEFAULT NULL::integer, prec_z integer DEFAULT NULL::integer, prec_m integer DEFAULT NULL::integer, with_sizes boolean DEFAULT NULL::boolean, with_boxes boolean DEFAULT NULL::boolean)
 RETURNS bytea
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$TWKBFromLWGEOMArray$function$
;

CREATE OR REPLACE FUNCTION public.st_asx3d(geom geometry, maxdecimaldigits integer DEFAULT 15, options integer DEFAULT 0)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 250
AS $function$SELECT public._ST_AsX3D(3,$1,$2,$3,'');$function$
;

CREATE OR REPLACE FUNCTION public.st_azimuth(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_azimuth$function$
;

CREATE OR REPLACE FUNCTION public.st_azimuth(geog1 geography, geog2 geography)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_azimuth$function$
;

CREATE OR REPLACE FUNCTION public.st_bdmpolyfromtext(text, integer)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline public.geometry;
	geom public.geometry;
BEGIN
	mline := public.ST_MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := public.ST_Multi(public.ST_BuildArea(mline));

	RETURN geom;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.st_bdpolyfromtext(text, integer)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
DECLARE
	geomtext alias for $1;
	srid alias for $2;
	mline public.geometry;
	geom public.geometry;
BEGIN
	mline := public.ST_MultiLineStringFromText(geomtext, srid);

	IF mline IS NULL
	THEN
		RAISE EXCEPTION 'Input is not a MultiLinestring';
	END IF;

	geom := public.ST_BuildArea(mline);

	IF public.ST_GeometryType(geom) != 'ST_Polygon'
	THEN
		RAISE EXCEPTION 'Input returns more then a single polygon, try using BdMPolyFromText instead';
	END IF;

	RETURN geom;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.st_boundary(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$boundary$function$
;

CREATE OR REPLACE FUNCTION public.st_boundingdiagonal(geom geometry, fits boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$ST_BoundingDiagonal$function$
;

CREATE OR REPLACE FUNCTION public.st_box2dfromgeohash(text, integer DEFAULT NULL::integer)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$box2d_from_geohash$function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(geom geometry, radius double precision, options text DEFAULT ''::text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$buffer$function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(geom geometry, radius double precision, quadsegs integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$ SELECT public.ST_Buffer($1, $2, CAST('quad_segs='||CAST($3 AS text) as text)) $function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(geography, double precision)
 RETURNS geography
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$SELECT public.geography(public.ST_Transform(public.ST_Buffer(public.ST_Transform(public.geometry($1), public._ST_BestSRID($1)), $2), public.ST_SRID($1)))$function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(geography, double precision, integer)
 RETURNS geography
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$SELECT public.geography(public.ST_Transform(public.ST_Buffer(public.ST_Transform(public.geometry($1), public._ST_BestSRID($1)), $2, $3), public.ST_SRID($1)))$function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(geography, double precision, text)
 RETURNS geography
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$SELECT public.geography(public.ST_Transform(public.ST_Buffer(public.ST_Transform(public.geometry($1), public._ST_BestSRID($1)), $2, $3), public.ST_SRID($1)))$function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(text, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Buffer($1::public.geometry, $2);  $function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(text, double precision, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Buffer($1::public.geometry, $2, $3);  $function$
;

CREATE OR REPLACE FUNCTION public.st_buffer(text, double precision, text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Buffer($1::public.geometry, $2, $3);  $function$
;

CREATE OR REPLACE FUNCTION public.st_buildarea(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_BuildArea$function$
;

CREATE OR REPLACE FUNCTION public.st_centroid(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$centroid$function$
;

CREATE OR REPLACE FUNCTION public.st_centroid(geography, use_spheroid boolean DEFAULT true)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_centroid$function$
;

CREATE OR REPLACE FUNCTION public.st_centroid(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Centroid($1::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_chaikinsmoothing(geometry, integer DEFAULT 1, boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_ChaikinSmoothing$function$
;

CREATE OR REPLACE FUNCTION public.st_cleangeometry(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CleanGeometry$function$
;

CREATE OR REPLACE FUNCTION public.st_clipbybox2d(geom geometry, box box2d)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_ClipByBox2d$function$
;

CREATE OR REPLACE FUNCTION public.st_closestpoint(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_closestpoint$function$
;

CREATE OR REPLACE FUNCTION public.st_closestpoint(geography, geography, use_spheroid boolean DEFAULT true)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_closestpoint$function$
;

CREATE OR REPLACE FUNCTION public.st_closestpoint(text, text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_ClosestPoint($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_closestpointofapproach(geometry, geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ClosestPointOfApproach$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterdbscan(geometry, eps double precision, minpoints integer)
 RETURNS integer
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ClusterDBSCAN$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterintersecting(geometry[])
 RETURNS geometry[]
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$clusterintersecting_garray$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterintersectingwin(geometry)
 RETURNS integer
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ClusterIntersectingWin$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterkmeans(geom geometry, k integer, max_radius double precision DEFAULT NULL::double precision)
 RETURNS integer
 LANGUAGE c
 WINDOW STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ClusterKMeans$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterwithin(geometry[], double precision)
 RETURNS geometry[]
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$cluster_within_distance_garray$function$
;

CREATE OR REPLACE FUNCTION public.st_clusterwithinwin(geometry, distance double precision)
 RETURNS integer
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ClusterWithinWin$function$
;

CREATE OR REPLACE FUNCTION public.st_collect(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$LWGEOM_collect$function$
;

CREATE OR REPLACE FUNCTION public.st_collect(geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_collect_garray$function$
;

CREATE OR REPLACE FUNCTION public.st_collectionextract(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_CollectionExtract$function$
;

CREATE OR REPLACE FUNCTION public.st_collectionextract(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_CollectionExtract$function$
;

CREATE OR REPLACE FUNCTION public.st_collectionhomogenize(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_CollectionHomogenize$function$
;

CREATE OR REPLACE FUNCTION public.st_combinebbox(box3d, geometry)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$BOX3D_combine$function$
;

CREATE OR REPLACE FUNCTION public.st_combinebbox(box3d, box3d)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$BOX3D_combine_BOX3D$function$
;

CREATE OR REPLACE FUNCTION public.st_combinebbox(box2d, geometry)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/postgis-3', $function$BOX2D_combine$function$
;

CREATE OR REPLACE FUNCTION public.st_concavehull(param_geom geometry, param_pctconvex double precision, param_allow_holes boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_ConcaveHull$function$
;

CREATE OR REPLACE FUNCTION public.st_contains(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$contains$function$
;

CREATE OR REPLACE FUNCTION public.st_containsproperly(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$containsproperly$function$
;

CREATE OR REPLACE FUNCTION public.st_convexhull(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$convexhull$function$
;

CREATE OR REPLACE FUNCTION public.st_coorddim(geometry geometry)
 RETURNS smallint
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_ndims$function$
;

CREATE OR REPLACE FUNCTION public.st_coverageclean(geom geometry, gapmaximumwidth double precision DEFAULT 0.0, snappingdistance double precision DEFAULT '-1.0'::numeric, overlapmergestrategy text DEFAULT 'MERGE_LONGEST_BORDER'::text)
 RETURNS geometry
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CoverageClean$function$
;

CREATE OR REPLACE FUNCTION public.st_coverageinvalidedges(geom geometry, tolerance double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CoverageInvalidEdges$function$
;

CREATE OR REPLACE FUNCTION public.st_coveragesimplify(geom geometry, tolerance double precision, simplifyboundary boolean DEFAULT true)
 RETURNS geometry
 LANGUAGE c
 WINDOW IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CoverageSimplify$function$
;

CREATE OR REPLACE FUNCTION public.st_coverageunion(geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_CoverageUnion$function$
;

CREATE OR REPLACE FUNCTION public.st_coveredby(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$coveredby$function$
;

CREATE OR REPLACE FUNCTION public.st_coveredby(geog1 geography, geog2 geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$geography_coveredby$function$
;

CREATE OR REPLACE FUNCTION public.st_coveredby(text, text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_CoveredBy($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_covers(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$covers$function$
;

CREATE OR REPLACE FUNCTION public.st_covers(geog1 geography, geog2 geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$geography_covers$function$
;

CREATE OR REPLACE FUNCTION public.st_covers(text, text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_Covers($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_cpawithin(geometry, geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CPAWithin$function$
;

CREATE OR REPLACE FUNCTION public.st_crosses(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$crosses$function$
;

CREATE OR REPLACE FUNCTION public.st_curven(geometry geometry, i integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CurveN$function$
;

CREATE OR REPLACE FUNCTION public.st_curvetoline(geom geometry, tol double precision DEFAULT 32, toltype integer DEFAULT 0, flags integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_CurveToLine$function$
;

CREATE OR REPLACE FUNCTION public.st_delaunaytriangles(g1 geometry, tolerance double precision DEFAULT 0.0, flags integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_DelaunayTriangles$function$
;

CREATE OR REPLACE FUNCTION public.st_dfullywithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$LWGEOM_dfullywithin$function$
;

CREATE OR REPLACE FUNCTION public.st_difference(geom1 geometry, geom2 geometry, gridsize double precision DEFAULT '-1.0'::numeric)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Difference$function$
;

CREATE OR REPLACE FUNCTION public.st_dimension(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_dimension$function$
;

CREATE OR REPLACE FUNCTION public.st_disjoint(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$disjoint$function$
;

CREATE OR REPLACE FUNCTION public.st_distance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Distance$function$
;

CREATE OR REPLACE FUNCTION public.st_distance(geog1 geography, geog2 geography, use_spheroid boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$geography_distance$function$
;

CREATE OR REPLACE FUNCTION public.st_distance(text, text)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Distance($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_distancecpa(geometry, geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_DistanceCPA$function$
;

CREATE OR REPLACE FUNCTION public.st_distancesphere(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$select public.ST_distance( public.geography($1), public.geography($2),false)$function$
;

CREATE OR REPLACE FUNCTION public.st_distancesphere(geom1 geometry, geom2 geometry, radius double precision)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_distance_sphere$function$
;

CREATE OR REPLACE FUNCTION public.st_distancespheroid(geom1 geometry, geom2 geometry, spheroid)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_distance_ellipsoid$function$
;

CREATE OR REPLACE FUNCTION public.st_distancespheroid(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_distance_ellipsoid$function$
;

CREATE OR REPLACE FUNCTION public.st_dump(geometry)
 RETURNS SETOF geometry_dump
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_dump$function$
;

CREATE OR REPLACE FUNCTION public.st_dumppoints(geometry)
 RETURNS SETOF geometry_dump
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dumppoints$function$
;

CREATE OR REPLACE FUNCTION public.st_dumprings(geometry)
 RETURNS SETOF geometry_dump
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_dump_rings$function$
;

CREATE OR REPLACE FUNCTION public.st_dumpsegments(geometry)
 RETURNS SETOF geometry_dump
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_dumpsegments$function$
;

CREATE OR REPLACE FUNCTION public.st_dwithin(geom1 geometry, geom2 geometry, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$LWGEOM_dwithin$function$
;

CREATE OR REPLACE FUNCTION public.st_dwithin(geog1 geography, geog2 geography, tolerance double precision, use_spheroid boolean DEFAULT true)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$geography_dwithin$function$
;

CREATE OR REPLACE FUNCTION public.st_dwithin(text, text, double precision)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_DWithin($1::public.geometry, $2::public.geometry, $3);  $function$
;

CREATE OR REPLACE FUNCTION public.st_endpoint(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_endpoint_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_envelope(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_envelope$function$
;

CREATE OR REPLACE FUNCTION public.st_equals(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$ST_Equals$function$
;

CREATE OR REPLACE FUNCTION public.st_estimatedextent(text, text, text, boolean)
 RETURNS box2d
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis-3', $function$gserialized_estimated_extent$function$
;

CREATE OR REPLACE FUNCTION public.st_estimatedextent(text, text, text)
 RETURNS box2d
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis-3', $function$gserialized_estimated_extent$function$
;

CREATE OR REPLACE FUNCTION public.st_estimatedextent(text, text)
 RETURNS box2d
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis-3', $function$gserialized_estimated_extent$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(box2d, double precision)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX2D_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(box box2d, dx double precision, dy double precision)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX2D_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(box3d, double precision)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(box box3d, dx double precision, dy double precision, dz double precision DEFAULT 0)
 RETURNS box3d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$BOX3D_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_expand(geom geometry, dx double precision, dy double precision, dz double precision DEFAULT 0, dm double precision DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_expand$function$
;

CREATE OR REPLACE FUNCTION public.st_exteriorring(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_exteriorring_polygon$function$
;

CREATE OR REPLACE FUNCTION public.st_filterbym(geometry, double precision, double precision DEFAULT NULL::double precision, boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$LWGEOM_FilterByM$function$
;

CREATE OR REPLACE FUNCTION public.st_findextent(text, text, text)
 RETURNS box2d
 LANGUAGE plpgsql
 STABLE PARALLEL SAFE STRICT
AS $function$
DECLARE
	schemaname alias for $1;
	tablename alias for $2;
	columnname alias for $3;
	myrec RECORD;
BEGIN
	FOR myrec IN EXECUTE 'SELECT public.ST_Extent("' || columnname || '") As extent FROM "' || schemaname || '"."' || tablename || '"' LOOP
		return myrec.extent;
	END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.st_findextent(text, text)
 RETURNS box2d
 LANGUAGE plpgsql
 STABLE PARALLEL SAFE STRICT
AS $function$
DECLARE
	tablename alias for $1;
	columnname alias for $2;
	myrec RECORD;

BEGIN
	FOR myrec IN EXECUTE 'SELECT public.ST_Extent("' || columnname || '") As extent FROM "' || tablename || '"' LOOP
		return myrec.extent;
	END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.st_flipcoordinates(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_FlipCoordinates$function$
;

CREATE OR REPLACE FUNCTION public.st_force2d(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_2d$function$
;

CREATE OR REPLACE FUNCTION public.st_force3d(geom geometry, zvalue double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Force3DZ($1, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_force3dm(geom geometry, mvalue double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_3dm$function$
;

CREATE OR REPLACE FUNCTION public.st_force3dz(geom geometry, zvalue double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_3dz$function$
;

CREATE OR REPLACE FUNCTION public.st_force4d(geom geometry, zvalue double precision DEFAULT 0.0, mvalue double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_4d$function$
;

CREATE OR REPLACE FUNCTION public.st_forcecollection(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_collection$function$
;

CREATE OR REPLACE FUNCTION public.st_forcecurve(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_force_curve$function$
;

CREATE OR REPLACE FUNCTION public.st_forcepolygonccw(geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$ SELECT public.ST_Reverse(public.ST_ForcePolygonCW($1)) $function$
;

CREATE OR REPLACE FUNCTION public.st_forcepolygoncw(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_clockwise_poly$function$
;

CREATE OR REPLACE FUNCTION public.st_forcerhr(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_clockwise_poly$function$
;

CREATE OR REPLACE FUNCTION public.st_forcesfs(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_force_sfs$function$
;

CREATE OR REPLACE FUNCTION public.st_forcesfs(geometry, version text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_force_sfs$function$
;

CREATE OR REPLACE FUNCTION public.st_frechetdistance(geom1 geometry, geom2 geometry, double precision DEFAULT '-1'::integer)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_FrechetDistance$function$
;

CREATE OR REPLACE FUNCTION public.st_fromflatgeobuf(anyelement, bytea)
 RETURNS SETOF anyelement
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$pgis_fromflatgeobuf$function$
;

CREATE OR REPLACE FUNCTION public.st_fromflatgeobuftotable(text, text, bytea)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$pgis_tablefromflatgeobuf$function$
;

CREATE OR REPLACE FUNCTION public.st_generatepoints(area geometry, npoints integer)
 RETURNS geometry
 LANGUAGE c
 PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_GeneratePoints$function$
;

CREATE OR REPLACE FUNCTION public.st_generatepoints(area geometry, npoints integer, seed integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_GeneratePoints$function$
;

CREATE OR REPLACE FUNCTION public.st_geogfromtext(text)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geogfromwkb(bytea)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geography_from_binary$function$
;

CREATE OR REPLACE FUNCTION public.st_geographyfromtext(text)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geohash(geom geometry, maxchars integer DEFAULT 0)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_GeoHash$function$
;

CREATE OR REPLACE FUNCTION public.st_geohash(geog geography, maxchars integer DEFAULT 0)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_GeoHash$function$
;

CREATE OR REPLACE FUNCTION public.st_geomcollfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE
	WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_GeometryCollection'
	THEN public.ST_GeomFromText($1,$2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_geomcollfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE
	WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_GeometryCollection'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_geomcollfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE
	WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_GeometryCollection'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_geomcollfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE
	WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_GeometryCollection'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_geometricmedian(g geometry, tolerance double precision DEFAULT NULL::double precision, max_iter integer DEFAULT 10000, fail_if_not_converged boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 5000
AS '$libdir/postgis-3', $function$ST_GeometricMedian$function$
;

CREATE OR REPLACE FUNCTION public.st_geometryfromtext(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geometryfromtext(text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geometryn(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_geometryn_collection$function$
;

CREATE OR REPLACE FUNCTION public.st_geometrytype(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geometry_geometrytype$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromewkb(bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOMFromEWKB$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromewkt(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$parse_WKT_lwgeom$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgeohash(text, integer DEFAULT NULL::integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 50
AS $function$ SELECT CAST(public.ST_Box2dFromGeoHash($1, $2) AS public.geometry); $function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgeojson(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geom_from_geojson$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgeojson(json)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_GeomFromGeoJson($1::text)$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgeojson(jsonb)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_GeomFromGeoJson($1::text)$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgml(text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geom_from_gml$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromgml(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public._ST_GeomFromGML($1, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromkml(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geom_from_kml$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfrommarc21(marc21xml text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 500
AS '$libdir/postgis-3', $function$ST_GeomFromMARC21$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromtext(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromtext(text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromtwkb(bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOMFromTWKB$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromwkb(bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_from_WKB$function$
;

CREATE OR REPLACE FUNCTION public.st_geomfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_SetSRID(public.ST_GeomFromWKB($1), $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_gmltosql(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public._ST_GeomFromGML($1, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_gmltosql(text, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geom_from_gml$function$
;

CREATE OR REPLACE FUNCTION public.st_hasarc(geometry geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_has_arc$function$
;

CREATE OR REPLACE FUNCTION public.st_hasm(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_hasm$function$
;

CREATE OR REPLACE FUNCTION public.st_hasz(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_hasz$function$
;

CREATE OR REPLACE FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$hausdorffdistance$function$
;

CREATE OR REPLACE FUNCTION public.st_hausdorffdistance(geom1 geometry, geom2 geometry, double precision)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$hausdorffdistancedensify$function$
;

CREATE OR REPLACE FUNCTION public.st_hexagon(size double precision, cell_i integer, cell_j integer, origin geometry DEFAULT '010100000000000000000000000000000000000000'::geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Hexagon$function$
;

CREATE OR REPLACE FUNCTION public.st_hexagongrid(size double precision, bounds geometry, OUT geom geometry, OUT i integer, OUT j integer)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_ShapeGrid$function$
;

CREATE OR REPLACE FUNCTION public.st_interiorringn(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_interiorringn_polygon$function$
;

CREATE OR REPLACE FUNCTION public.st_interpolatepoint(line geometry, point geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_InterpolatePoint$function$
;

CREATE OR REPLACE FUNCTION public.st_intersection(geom1 geometry, geom2 geometry, gridsize double precision DEFAULT '-1'::integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Intersection$function$
;

CREATE OR REPLACE FUNCTION public.st_intersection(geography, geography)
 RETURNS geography
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$SELECT public.geography(public.ST_Transform(public.ST_Intersection(public.ST_Transform(public.geometry($1), public._ST_BestSRID($1, $2)), public.ST_Transform(public.geometry($2), public._ST_BestSRID($1, $2))), public.ST_SRID($1)))$function$
;

CREATE OR REPLACE FUNCTION public.st_intersection(text, text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$ SELECT public.ST_Intersection($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_intersects(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$ST_Intersects$function$
;

CREATE OR REPLACE FUNCTION public.st_intersects(geog1 geography, geog2 geography)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$geography_intersects$function$
;

CREATE OR REPLACE FUNCTION public.st_intersects(text, text)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_Intersects($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_inversetransformpipeline(geom geometry, pipeline text, to_srid integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public.postgis_transform_pipeline_geometry($1, $2, FALSE, $3)$function$
;

CREATE OR REPLACE FUNCTION public.st_isclosed(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_isclosed$function$
;

CREATE OR REPLACE FUNCTION public.st_iscollection(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$ST_IsCollection$function$
;

CREATE OR REPLACE FUNCTION public.st_isempty(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_isempty$function$
;

CREATE OR REPLACE FUNCTION public.st_ispolygonccw(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_IsPolygonCCW$function$
;

CREATE OR REPLACE FUNCTION public.st_ispolygoncw(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_IsPolygonCW$function$
;

CREATE OR REPLACE FUNCTION public.st_isring(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$isring$function$
;

CREATE OR REPLACE FUNCTION public.st_issimple(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$issimple$function$
;

CREATE OR REPLACE FUNCTION public.st_isvalid(geometry, integer)
 RETURNS boolean
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT (public.ST_isValidDetail($1, $2)).valid$function$
;

CREATE OR REPLACE FUNCTION public.st_isvalid(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$isvalid$function$
;

CREATE OR REPLACE FUNCTION public.st_isvaliddetail(geom geometry, flags integer DEFAULT 0)
 RETURNS valid_detail
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$isvaliddetail$function$
;

CREATE OR REPLACE FUNCTION public.st_isvalidreason(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$isvalidreason$function$
;

CREATE OR REPLACE FUNCTION public.st_isvalidreason(geometry, integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$
	SELECT CASE WHEN valid THEN 'Valid Geometry' ELSE reason END FROM (
		SELECT (public.ST_isValidDetail($1, $2)).*
	) foo
	$function$
;

CREATE OR REPLACE FUNCTION public.st_isvalidtrajectory(geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_IsValidTrajectory$function$
;

CREATE OR REPLACE FUNCTION public.st_largestemptycircle(geom geometry, tolerance double precision DEFAULT 0.0, boundary geometry DEFAULT '0101000000000000000000F87F000000000000F87F'::geometry, OUT center geometry, OUT nearest geometry, OUT radius double precision)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_LargestEmptyCircle$function$
;

CREATE OR REPLACE FUNCTION public.st_length(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_length2d_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_length(geog geography, use_spheroid boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_length$function$
;

CREATE OR REPLACE FUNCTION public.st_length(text)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$ SELECT public.ST_Length($1::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_length2d(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_length2d_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_length2dspheroid(geometry, spheroid)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_length2d_ellipsoid$function$
;

CREATE OR REPLACE FUNCTION public.st_lengthspheroid(geometry, spheroid)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_length_ellipsoid_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_letters(letters text, font json DEFAULT NULL::json)
 RETURNS geometry
 LANGUAGE plpgsql
 IMMUTABLE PARALLEL SAFE COST 250
 SET standard_conforming_strings TO 'on'
AS $function$
DECLARE
  letterarray text[];
  letter text;
  geom geometry;
  prevgeom geometry = NULL;
  adjustment float8 = 0.0;
  position float8 = 0.0;
  text_height float8 = 100.0;
  width float8;
  m_width float8;
  spacing float8;
  dist float8;
  wordarr geometry[];
  wordgeom geometry;
  -- geometry has been run through replace(encode(st_astwkb(geom),'base64'), E'\n', '')
  font_default_height float8 = 1000.0;
  font_default json = '{
  "!":"BgACAQhUrgsTFOQCABQAExELiwi5AgAJiggBYQmJCgAOAg4CDAIOBAoEDAYKBgoGCggICAgICAgGCgYKBgoGCgQMBAoECgQMAgoADAIKAAoADAEKAAwBCgMKAQwDCgMKAwoFCAUKBwgHBgcIBwYJBgkECwYJBAsCDQILAg0CDQANAQ0BCwELAwsDCwUJBQkFCQcHBwcHBwcFCQUJBQkFCQMLAwkDCQMLAQkACwEJAAkACwIJAAsCCQQJAgsECQQJBAkGBwYJCAcIBQgHCAUKBQoDDAUKAQwDDgEMAQ4BDg==",
  "&":"BgABAskBygP+BowEAACZAmcAANsCAw0FDwUNBQ0FDQcLBw0HCwcLCQsJCwkLCQkJCwsJCwkLCQ0HCwcNBw8HDQUPBQ8DDwMRAw8DEQERAREBEQERABcAFQIXAhUCEwQVBBMGEwYTBhEIEQgPChEKDwoPDA0MDQwNDgsOCRAJEAkQBxAHEgUSBRQFFAMUAxQBFgEWARgAigEAFAISABICEgQQAhAEEAQQBg4GEAoOCg4MDg4ODgwSDgsMCwoJDAcMBwwFDgUMAw4DDgEOARABDgEQARIBEAASAHgAIAQeBB4GHAgaChoMGA4WDhYQFBISEhISDhQQFAwWDBYKFgoYBhgIGAQYBBgCGgAaABgBGAMYAxYHFgUWCRYJFAsUCxIPEg0SERARDhMOFQwVDBcIGQYbBhsCHQIfAR+dAgAADAAKAQoBCgEIAwgFBgUGBQYHBAUEBwQHAgcCBwIHAAcABwAHAQcBBwMHAwUDBwUFBQUHBQUBBwMJAQkBCQAJAJcBAAUCBQAFAgUEBQIDBAUEAwQDBgMEAQYDBgEGAAgBBgAKSeECAJ8BFi84HUQDQCAAmAKNAQAvExMx",
  "\"":"BgACAQUmwguEAgAAkwSDAgAAlAQBBfACAIACAACTBP8BAACUBA==",
  "''":"BgABAQUmwguEAgAAkwSDAgAAlAQ=",
  "(":"BgABAUOQBNwLDScNKw0rCysLLwsxCTEJMwc1BzcHNwM7AzsDPwE/AEEANwI1AjMEMwIzBjEGLwYvCC0ILQgrCCkKKQonCicMJbkCAAkqCSoHLAksBywFLgcuBS4FMAMwAzADMgEwATQBMgA0ADwCOgI6BDoEOAY4BjYINgg2CjQKMgoyCjIMMAwwDi7AAgA=",
  ")":"BgABAUMQ3Au6AgAOLQwvDC8KMQoxCjEKMwg1CDUGNQY3BDcEOQI5AjkAOwAzATEBMQExAy8DLwMvBS8FLQctBS0HKwktBykJKwkpswIADCYKKAooCioIKggsCC4ILgYwBjAGMgQ0AjQCNAI2ADgAQgFAAz4DPAM8BzgHOAc2CTQJMgsyCzALLg0sDSoNKg==",
  "+":"BgABAQ3IBOwGALcBuAEAANUBtwEAALcB0wEAALgBtwEAANYBuAEAALgB1AEA",
  "/":"BgABAQVCAoIDwAuyAgCFA78LrQIA",
  "4":"BgABAhDkBr4EkgEAEREApwJ/AADxARIR5QIAEhIA9AHdAwAA7ALIA9AG6gIAEREA8QYFqwIAAIIDwwH/AgABxAEA",
  "v":"BgABASDmA5AEPu4CROwBExb6AgAZFdMC0wgUFaECABIU0wLWCBcW+AIAExVE6wEEFQQXBBUEFwQVBBUEFwQVBBUEFwQVBBUEFwQXBBUEFwYA",
  ",":"BgABAWMYpAEADgIOAgwCDgQMBAoGDAYKBgoICAgICAgICAoGCgYKBAoEDAQKBAoCDAIKAgwCCgAKAAwACgEMAQoBCgMMAwoDCgUKBQgFCgUIBwYJCAcGCQYJBAsGCQQLAg0CCwINAg0AAwABAAMAAwADAQMAAwADAAMBBQAFAQcBBwEHAwcBCQMJAQsDCwMLAw0FDQMNBQ8FDwURBxMFEwkTBxcJFwkXswEAIMgBCQYJBgkGBwYJCAcIBQgHCgUKBQoFDAEMAwwBDgEOABA=",
  "-":"BgABAQUq0AMArALEBAAAqwLDBAA=",
  ".":"BgABAWFOrAEADgIOAg4CDgQMBAoGDAYKBgoICAgKCAgIBgoGCgYKBgoEDAQKBAwECgIMAAwCDAAMAAwBCgAMAQoDDAMKAwoDCgUKBQgFCgUIBwgJBgcICQYJBgsGCQQLAg0CDQINAA0ADQENAQ0BCwMNAwkFCwUJBQkHBwcJBwUHBwkFCQUJBQkDCwMJAwsDCQELAAsBCwALAAsCCQALAgkECwQJBAkECQYJBgcGBwgJBgcKBQgHCgUKBQwFCgEOAwwBDgEOAA4=",
  "0":"BgABAoMB+APaCxwAHAEaARoDFgMYBRYFFAcUBxIJEgkQCRALEAsOCwwNDA0MDQoPCg0IDwgPBhEGDwYRBA8EEQIRAhMCEQITABMA4QUAEQETAREBEQMRAxEFEQURBREHDwkPBw8JDwsNCw0LDQ0NDQsNCw8JEQkRCREJEwcTBxUFFQUVAxUDFwEXARkAGQAZAhcCFwQXBBUGEwYTCBMIEQoRCg8KDwoPDA0MDQ4NDgsOCQ4JEAkQBxAHEAUSBRIDEgMSAxIDEgESARQAEgDiBQASAhQCEgISBBIEEgYSBhIGEggQChAIEAoQDBAMDgwODg4ODA4MEgwQChIKEggUCBQIFgYWBBYGGAQYAhgCGgILZIcDHTZBEkMRHTUA4QUeOUITRBIePADiBQ==",
  "2":"BgABAWpUwALUA44GAAoBCAEKAQgDBgMGBQYFBgUEBwQFBAUCBwIHAgUABwAHAAUBBwMFAQcFBQMHBQUHBQcFBwMJAwkBCQELAQsAC68CAAAUAhIAFAISBBQCEgQUBBIEEgYUCBIGEAgSChAKEAoQDBAMDg4ODgwQDBIMEgoSChQIFggWCBgGGAQaAhwCHAIWABQBFgEUARQDFAMSAxQFEgUSBxIHEAkQCRALDgsODQ4NDA8KDwwRCBMKEwgTBhUGFwQXBBcEGwAbABsAHQEftwPJBdIDAACpAhIPzwYAFBIArgI=",
  "1":"BgABARCsBLALAJ0LEhERADcA2QEANwATABQSAOYIpwEAALgCERKEBAASABER",
  "3":"BgABAZ0B/gbEC/sB0QQOAwwBDAMMAwwFCgMKBQoFCgUIBwoFCAcICQgJBgkICQYLCAsECwYLBA0GDwINBA8CDwQRAhECEQITABUCFQAVAH0AEQETAREBEQETAxEDEQURBREFDwcRBw8JDwkNCQ8LDQsNDQsNCw0LDwsPCREJEQcRBxMFFQUVBRUDFwEXARkAGQAZAhkCFwQVBBUEEwYTCBEIEQgRCg0MDwoNDA0OCw4LDgkQCRAHEAkQBRAFEgUSAxIDFAMSAxYBFAEWARYAFqQCAAALAgkCCQQHAgcGBwYHBgUIBQYDCAMIAwYDCAEIAQgACAAIAAgCCAIIAgYCCAQIBAgGBgYEBgQIBAoCCgAKAAwAvAEABgEIAAYBBgMGAwQDBgMEBQQDBAUCBQQFAgUABwIFAJkBAACmAaIB3ALbAgAREQDmAhIRggYA",
  "5":"BgABAaAB0APgBxIAFAESABIBEgMSARADEgMQAxIFEAcOBRAHDgkOCQ4JDgsMCwwLCgsKDQoPCA0IDwgPBhEEEwYTAhMEFwIXABcAiQIAEwETABEBEQMTAxEDDwMRBQ8FDwUPBw8JDQcNCQ0LDQsLCwsNCw0JDwkPCREHEQcTBxMFEwMVAxcDGQEZARkAFwAVAhUCFQQTBBMGEwYRCBEIDwoPCg8KDQwNDA0MCw4LDgkOCRAJEAcOBxAHEgUQBRIDEAMSAxIBEgEUARIAFLgCAAAFAgUABQIFBAUCBQQDBAUEAwYDBgMIAwgBCAEIAQoACAAIAgYACAQGAgQEBgQEBAQGBAQCBgIGAgYCBgIIAAYA4AEABgEIAAYBBgMGAQQDBgMEAwQFBAMCBQQFAgUABwIFAPkBAG+OAQCCBRESAgAAAuYFABMRAK8CjQMAAJ8BNgA=",
  "7":"BgABAQrQBsILhQOvCxQR7wIAEhK+AvYIiwMAAKgCERKwBgA=",
  "6":"BgABAsYBnAOqBxgGFgYYBBYEFgIWABQBFgEUAxQDFAUUBRIFEAcSCRAJEAkOCw4NDgsMDQoPCg8KDwgRCBEGEQYRBBMCEwITAhUAkwIBAAERAREBEQEPAxEFEQMPBREFDwcPBw8HDwkNCQ0LDQsNCwsNCw0LDQkPCQ8JDwcRBxEHEwUTAxMFFQEXAxcBGQAVABUCEwIVBBMEEQYTBhEIEQgPChEKDQoPDA0MDQwNDgsOCxALDgkQCRAHEgcQBxIFEgUSBRIBFAMSARIBFAASAOIFABACEgIQAhIEEAQQBhIGEAYQCBAKEAgOChAMDgwMDA4ODA4MDgwODBAKEAoQChIIEggSBhQGFgYUAhYCGAIYABoAGAEYARYBFgMUBRQFEgUSBxAHEAcQCQ4LDgkMCwwNDA0KDQgPCg0GEQgPBhEEEQQRBBMEEwITAhMCFQIVABWrAgAACgEIAQoBCAEGAwYDBgUGBQQFBAUEBQQFAgUABwIFAAUABwEFAAUBBQMFAwUDBQMFBQMFAwUBBQEHAQkBBwAJAJcBDUbpBDASFi4A4AETLC8SBQAvERUrAN8BFC0yEQQA",
  "8":"BgABA9gB6gPYCxYAFAEUARYBEgMUBRQFEgUSBxIHEAcSCQ4JEAkOCw4LDgsMDQwNCg0KDQoPCg8IDwgPBhEGEQQPBBMCEQIRABMAQwAxAA8BEQEPAREDDwMRAw8FEQUPBxEJDwkPCQ8NDw0PDQ8IBwYHCAcGBwgHBgkGBwYJBgcECQYJBAkGCQQJBAsECwQLBA0CCwINAg8CDwIPAA8AaQATAREBEwERAxEFEQURBREHEQcPBw8JDwkPCw8LDQsNDQ0LCw0LDwsNCQ8JDwcPBw8HEQURAxEFEQMRARMBEwFDABEAEwIRAhEEEQQRBg8GEQgPCA8KDwoPCg0MDQwNDAsOCw4LDgkQCRAJDgkQBxIHEAcSBRADEgMUAxIBFAEUABQAagAOAhAADgIOAg4EDAIOBAwEDAQMBgwECgYMBAoGCAYKBgoGCggKBgoICgYICAoICA0MCwwLDgsOCRAHEAcQBxIFEgUSAxIDEgMSARABEgASADIARAASAhICEgQSAhIGEAYSBhAIEAgQCBAKDgoODA4MDgwMDgwODA4KEAwQCBIKEggSCBQIFAYUBBQEFgQWAhYCGAANT78EFis0EwYANBIYLgC0ARcsMRQFADERGS0AswELogHtAhcuNxA3DRkvALMBGjE6ETYSGDIAtAE=",
  "9":"BgABAsYBpASeBBcFFQUXAxUDFQEVABMCFQITBBMEEwYRBhMGDwgRCg8KDwoNDA0OCwwNDgkQCRAJEAcSBxIFEgUSAxQBFAEUARYAlAICAAISAhICEgQSAhAGEgQQBhIGEAgSCA4IEAoOChAMDAwODAwODA4MEAoOChAKEAgSCBIIFAYUBBQGFgIYBBgCGgAWABYBFAEWAxQDEgUUBRIHEgcQCRIJEAkOCw4LDgsODQwNDA0MDwoPCg8IDwgRCBEGEQYRBhEEEQITAhECEwARAOEFAA8BEQEPAREDDwMPBREFDwUPBw8JDwcNCQ8LDQsLCw0NCw0LDQsNCw8JEQkPCREHEQcTBRMFEwUTARUBFQEXABkAFwIXAhcCFQQTBhMGEQYRCA8IDwgNCg8MCwoLDAsOCQ4JDgkQBxAHEAUQBRIFEgMSAxQDFAEUAxQAFgEWABamAgAACwIJAgkCCQIHBAcEBwYFBgUGAwYDBgMGAQgBBgEIAAgABgIIAgYCBgQGBAYEBgYGBgQIBAgECAIKAgoCCgAMAJgBDUXqBC8RFS0A3wEUKzARBgAwEhYsAOABEy4xEgMA",
  ":":"BgACAWE0rAEADgIOAg4CDgQMBAoGDAYKBgoICAgKCAgIBgoGCgYKBgoEDAQKBAwECgIMAAwCDAAMAAwBCgAMAQoDDAMKAwoDCgUKBQgFCgUIBwgJBgcICQYJBgsGCQQLAg0CDQINAA0ADQENAQ0BCwMNAwkFCwUJBQkHBwcJBwUHBwkFCQUJBQkDCwMJAwsDCQELAAsBCwALAAsCCQALAgkECwQJBAkECQYJBgcGBwgJBgcKBQgHCgUKBQwFCgEOAwwBDgEOAA4BYQDqBAAOAg4CDgIOBAwECgYMBgoGCggICAoICAgGCgYKBgoGCgQMBAoEDAQKAgwADAIMAAwADAEKAAwBCgMMAwoDCgMKBQoFCAUKBQgHCAkGBwgJBgkGCwYJBAsCDQINAg0ADQANAQ0BDQELAw0DCQULBQkFCQcHBwkHBQcHCQUJBQkFCQMLAwkDCwEJAwsACwELAAsACwIJAAsECQILBAkECQQJBgkGBwYHCAkGBwoFCAcKBQoFDAUKAQ4DDAEOAQ4ADg==",
  "x":"BgABARHmAoAJMIMBNLUBNrYBMIQB1AIA9QG/BI4CvwTVAgA5hgFBwAFFxwE1fdUCAI4CwATzAcAE1AIA",
  ";":"BgACAWEslgYADgIOAg4CDgQMBAoGDAYKBgoICAgKCAgIBgoGCgYKBgoEDAQKBAwECgIMAAwCDAAMAAwBCgAMAQoDDAMKAwoDCgUKBQgFCgUIBwgJBgcICQYJBgsGCQQLAg0CDQINAA0ADQENAQ0BCwMNAwkFCwUJBQkHBwcJBwUHBwkFCQUJBQkDCwMJAwsBCQMLAAsBCwALAAsCCQALBAkCCwQJBAkECQYJBgcGBwgJBgcKBQgHCgUKBQwFCgEOAwwBDgEOAA4BYwjxBAAOAg4CDAIOBAwECgYMBgoGCggICAgICAgICgYKBgoECgQMBAoECgIMAgoCDAIKAAoADAAKAQwBCgEKAwwDCgMKBQoFCAUKBQgHBgkIBwYJBgkECwYJBAsCDQILAg0CDQADAAEAAwADAAMBAwADAAMAAwEFAAUBBwEHAQcDBwEJAwkBCwMLAwsDDQUNAw0FDwUPBREHEwUTCRMHFwkXCRezAQAgyAEJBgkGCQYHBgkIBwgFCAcKBQoFCgUMAQwDDAEOAQ4AEA==",
  "=":"BgACAQUawAUA5gHEBAAA5QHDBAABBQC5AgDsAcQEAADrAcMEAA==",
  "B":"BgABA2e2BMQLFgAUARQBFAEUAxIDEgUSBRIFEAcQBxAJDgkOCQ4LDgsMCwwNDA0KDQgNCg0IDwYPBg8GDwQRBBEEEQIRAhMAEwAHAAkABwEHAAkBCQAHAQkBCQEHAQkBCQMJAwcDCQMJAwkFBwUJAwkHCQUHBQkHCQcJBwcHBwkHBwcJBwsHCQUQBQ4FDgcOCQ4JDAkMCwoNCg0IDwgRBhMEFQQXAhcCGwDJAQEvAysFJwklDSMPHREbFRkXFRsTHw8fCyUJJwcrAy0B6wMAEhIAoAsREuYDAAiRAYEElgEAKioSSA1EOR6JAQAA0wEJkAGPBSwSEiwAzAETKikSjwEAAMUCkAEA",
  "A":"BgABAg/KBfIBqQIAN98BEhHzAgAWEuwCngsREvwCABMR8gKdCxIR8QIAFBI54AEFlwGCBk3TA6ABAE3UAwMA",
  "?":"BgACAe4BsgaYCAAZABkBFwEXBRUDEwUTBxEHEQcPCQ8JDQkNCQ0LCwsLCwsLCQsJCwcNBwsHDQcLBQsFDQULAwkFCwMLAwkDCQMBAAABAQABAAEBAQABAAEAAQABAAABAQAAAQEAEwcBAQABAAMBAwADAAUABQAFAAcABwAFAAcABwAFAgcABQAHAAUAW7cCAABcABgBFgAUAhQAFAISAhACEAIQBA4EDgQMBgwGDAYMBgoICgYKCAgKCggICAgKBgoICgYMCAwGDAgOBg4GEAYQBgIAAgIEAAICBAACAgQCBAIKBAoGCAQKBggIBgYICAYIBggGCgQIBAoECAQKAggCCgIKAAgACgAKAAgBCAEKAwgDCAMIAwgFBgMIBQYHBAUGBQQFBAcCBQQHAgcCCQIHAgkCBwAJAgkACQAJAAkBCQAJAQsACQELAQsDCwELAwsDCwMLAwsDCwULAwsFCwMLBV2YAgYECAQKBAwGDAQMBhAIEAYSBhIIEgYUBhIEFgYUBBYEFgQWAhgCFgIYABYAGAAYARgBGAMWBRYHFgcWCRYLFA0IBQYDCAUIBwYFCAcGBwgHBgcICQYJCAkGCQYJCAsGCwYLBgsGDQYNBA0GDQQNBA8EDwQPAg8EEQIRAhEAEQITAWGpBesGAA4CDgIOAg4EDAQKBgwGCgYKCAgICggICAYKBgoGCgYKBAwECgQMBAoCDAAMAgwADAAMAQoADAEKAwwDCgMKAwoFCgUIBQoFCAcICQYHCAkGCQYLBgkECwINAg0CDQANAA0BDQENAQsDDQMJBQsFCQUJBwcHCQcFBwcJBQkFCQUJAwsDCQMLAwkBCwALAQsACwALAgkACwIJBAsECQQJBAkGCQYHBgcICQYHCgUIBwoFCgUMBQoBDgMMAQ4BDgAO",
  "C":"BgABAWmmA4ADAAUCBQAFAgUEBQIDBAUEAwQDBgMEAQYDBgEGAAgBBgDWAgAAwQLVAgATABMCEQITBBEEEQQRBhEIEQgPCA8KDwoNCg0MDQwNDAsOCw4LDgkOCxAHEAkQBxIHEgUSBRIDEgEUARIBFAAUAMIFABQCFAISBBQEEgQSBhIIEggSCBAKEAoQCg4MDgwODA4ODA4MDgwQDA4KEggQChIIEggSBhIGFAQSAhQCEgIUAMYCAADBAsUCAAUABwEFAAUBBQMDAQUDAwMDAwMFAQMDBQEFAAUBBwAFAMEF",
  "L":"BgABAQmcBhISEdkFABIQALQLwgIAAIEJ9AIAAK8C",
  "D":"BgABAkeyBMQLFAAUARIBFAESAxIDEgMSBRIFEAcQBxAHDgkOCQ4LDgsMCwwNDA0KDwoPCg8IDwgRCBEGEwQTBBMEEwIVAhUAFwDBBQAXARcBFwMTAxUDEwUTBxEHEQcPCQ8JDwkNCw0LCwsLDQsNCQ0JDQcPBw8HDwcRBREFEQMRAxEDEwERARMBEwDfAwASEgCgCxES4AMACT6BAxEuKxKLAQAAvwaMAQAsEhIsAMIF",
  "F":"BgABARGABoIJ2QIAAIECsgIAEhIA4QIRErECAACvBBIR5QIAEhIAsgucBQASEgDlAhES",
  "E":"BgABARRkxAuWBQAQEgDlAhES0QIAAP0BtgIAEhIA5wIRFLUCAAD/AfACABISAOUCERLDBQASEgCyCw==",
  "G":"BgABAZsBjgeIAgMNBQ8FDQUNBQ0HCwcNBwsHCwkLCQsJCwsJCwsLCQsJDQkLBw0HDwcNBw8FDwUPAw8DEQMPAxEBEQERARMBEQAXABUCFwIVAhMEFQQTBhMGEwYRCBEIDwoRCg8KDwwNDA0MDQ4LDgkQCRAJEAcQBxIFEgUUBRQDFAMUARYBFgEYAMoFABQCFAASBBQCEgQSBBIEEgYSBhAGEAgQCBAKDgoOCg4MDgwMDgwOChAKEAoSCBIIFAgUBhQEGAYWAhgEGAIaAOoCAAC3AukCAAcABwEFAQUBBQMFAwMFAwUDBQEFAQcBBQEFAQUABwAFAMUFAAUCBwIFAgUCBQQFBAMGBQYDBgUGAwgDBgMIAQgDCAEIAQoBCAEIAAgACgAIAAgCCAIIAggECgQGBAgECAYIBgC6AnEAAJwCmAMAAJcF",
  "H":"BgABARbSB7ILAQAAnwsSEeUCABISAOAE5QEAAN8EEhHlAgASEgCiCxEQ5gIAEREA/QPmAQAAgAQPEOYCABER",
  "I":"BgABAQmuA7ILAJ8LFBHtAgAUEgCgCxMS7gIAExE=",
  "J":"BgABAWuqB7ILALEIABEBEwERAREDEwMRAxEFEQURBw8HEQcPCQ0LDwsNCw0NDQ0LDwsPCxEJEQkTCRMJFQcVBxcFFwMZAxsBGwEbAB8AHQIbAhsEGQYXBhcGFQgTCBMKEwoRDA8KDwwNDA0OCw4LDgkQCRAJEAcQBRIFEgUSAxQDEgESARIBFAESABIAgAEREtoCABERAn8ACQIHBAcEBwYHBgUIBQoDCgMKAwoDDAEKAQwBCgEMAAwACgAMAgoCDAIKBAoECgYKBggGBgYGCAQGBAgCCgAIALIIERLmAgAREQ==",
  "M":"BgACAQRm1gsUABMAAAABE5wIAQDBCxIR5QIAEhIA6gIK5gLVAe0B1wHuAQztAgDhAhIR5QIAEhIAxAsUAPoDtwT4A7YEFgA=",
  "K":"BgABAVXMCRoLBQsDCQMLAwsDCwMLAwsBCwELAQsBCwELAQ0ACwELAAsADQALAg0ACwILAA0CCwILAgsCDQQLBAsECwYNBAsGCwYLCAsGCwgJCgsICQoJCgkMCQwJDAkOCRALEAkQCRKZAdICUQAAiwQSEecCABQSAKALExLoAgAREQC3BEIA+AG4BAEAERKCAwAREdkCzQXGAYUDCA0KDQgJCgkMBwoFDAUMAQwBDgAMAg4CDAQOBAwGDghmlQI=",
  "O":"BgABAoMBsATaCxwAHAEaARoDGgMYBRYFFgcWBxQJEgkSCRILEAsODQ4NDg0MDwoNDA8KDwgPCBEIDwYRBg8GEQQRAhMCEQITABMA0QUAEQETAREBEQMTBREFEQURBxEHDwcRCQ8LDQsPCw0NDQ0NDwsPCw8LEQkTCRMJEwkVBxUHFwUXAxkDGQEbARsAGwAZAhkCGQQXBhcGFQYVCBUIEwoRChEMEQoRDA8MDQ4NDg0OCxAJEAsQCRAHEgcSBxIFFAMSAxIDEgEUARIAEgDSBQASAhQCEgISBBIEEgYSBhIIEggQCBAKEgwODBAMEA4ODg4QDhIMEAwSChQKFAgUCBYIFgYYBBoGGgQcAh4CHgILggGLAylCWxZbFSlBANEFKklcGVwYKkwA0gU=",
  "N":"BgABAQ+YA/oEAOUEEhHVAgASEgC+CxQAwATnBQDIBRMS2AIAExEAzQsRAL8ElgU=",
  "P":"BgABAkqoB5AGABcBFQEVAxMDEwMTBREHEQcRBw8JDwkNCQ0LDQsNCwsNCw0JDQkNCQ8HDwcPBxEFEQURAxEDEQMTAREBEwETAH8AAIMDEhHlAgASEgCgCxES1AMAFAAUARIAFAESAxIDEgMSAxIFEAUQBRAHDgkOCQ4JDgsMCwwNDA0KDQoNCg8IDwgRCBEGEwQTBBUEFQIXAhkAGQCzAgnBAsoCESwrEn8AANUDgAEALBISLgDYAg==",
  "R":"BgABAj9msgsREvYDABQAFAESARQBEgESAxIDEgUSBRAFEAcQBw4JDgkOCQ4LDAsMDQwLCg0KDwoNCA8IDwgPBhEEEwYTAhMEFQIXABcAowIAEwEVARMDEwMTBRMFEQcTBxELEQsRDQ8PDREPEQ0VC8QB/QMSEfkCABQSiQGyA3EAALEDFBHnAgASEgCgCwnCAscFogEALhISLACqAhEsLRKhAQAApQM=",
  "Q":"BgABA4YBvAniAbkB8wGZAYABBQUFAwUFBQUHBQUDBwUFBQcFBQMHBQcDBwUJAwcDCQMJAwkDCQMJAQsDCwMLAQsDCwENAw0BDQEPAA8BDwAPABsAGwIZAhcEGQQXBBUGFQgVCBMIEQoTChEKDwwPDA8ODQ4NDgsQCxAJEAkQBxIHEgUSBRQFFAMUARQDFAEWABYAxgUAEgIUAhICEgQSBBIGEgYSCBIIEAgQChIMDgwQDBAODg4OEA4SDBAMEgoUChQIFAgWCBYGGAQaBhoEHAIeAh4CHAAcARoBGgMaAxgFFgUWBxYHFAkSCRIJEgsQCw4NDg0ODQwPCg0MDwoPCA8IEQgPBhEGDwYRBBECEwIRAhMAEwC7BdgBrwEImQSyAwC6AylAWxZbFSk/AP0BjAK7AQeLAoMCGEc4J0wHVBbvAaYBAEM=",
  "S":"BgABAYMC8gOEBxIFEgUQBxIFEgcSBxIJEgcSCRIJEAkQCRALEAsOCw4NDg0MDQ4PDA0KEQoPChEKEQgRCBMGFQQTBBcCFQAXABkBEwARAREBEQMPAQ8DDwMPAw0DDQUNAw0FCwULBwsFCwUJBwsFCQcHBQkHCQUHBwcHBwUHBwUFBQcHBwUHAwcFEQsRCxMJEwkTBxMFEwUVBRUDFQMVARMBFwEVABUAFQIVAhUCFQQVBBUEEwYVBhMIEwgTCBMIEwgRCBMKEQgRCmK6AgwFDgUMAw4FEAUOBRAFEAUQBRAFEAMSAw4DEAMQAxABEAEOAQ4AEAIMAg4CDgQMBAwGCggKCAoKBgwGDgYQBBACCgAMAAoBCAMKBQgFCAcIBwgJCAsGCQgLCA0IDQgNCA8IDQgPCA8IDwgPChEIDwgPCBEKDwoPDBEMDwwPDg8ODw4NEA0QCxALEgsSCRIHEgcUBRQFGAUYAxgBGgEcAR4CJAYkBiAIIAweDBwQHBAYEhgUFBYUFhQWEBoQGg4aDBwKHAoeBh4GIAQgAiACIgEiASIFIgUiBSAJIgkgCyINZ58CBwQJAgkECwQLAgsECwINBA0CDQQNAg0CDQALAg0ADQANAAsBCwELAQsDCwULBQkFCQcHBwcJBwkFCwMLAw0BDQENAAsCCwQLBAkGCQgJCAkKBwoJCgcMBQoHDAcMBQwF",
  "V":"BgABARG2BM4DXrYEbKwDERL0AgAVEesCnQsSEfsCABQS8QKeCxES8gIAExFuqwNgtQQEAA==",
  "T":"BgABAQskxAv0BgAAtQKVAgAA+wgSEeUCABISAPwImwIAALYC",
  "U":"BgABAW76B7ALAKMIABcBFwMXARUFFQUTBxMHEwkRCREJEQsPDQ0LDw0NDwsPCw8LEQkPCRMJEQcTBxMFEwUVBRUDEwMXARUBFQEXABUAEwIVAhMCFQQTBBUEEwYTBhMIEwgRChEIEQwRDA8MDw4PDg0OCxANEAsSCRIJEgcUBxQHFAMWBRYBGAEYARgApggBAREU9AIAExMAAgClCAALAgkECQQHBAcIBwgHCAUKBQoDCgMKAwwBCgEMAQwADAAMAgoCDAIKAgoECgQKBggGCAYICAYKBAgCCgIMAgwApggAARMU9AIAExM=",
  "X":"BgABARmsCBISEYkDABQSS54BWYICXYkCRZUBEhGJAwAUEtYCzgXVAtIFExKIAwATEVClAVj3AVb0AVKqAREShgMAERHXAtEF2ALNBQ==",
  "W":"BgABARuODcQLERHpAp8LFBHlAgASEnW8A2+7AxIR6wIAFBKNA6ALERKSAwATEdQB7wZigARZ8AIREugCAA8RaKsDYsMDXsoDaqYDExLqAgA=",
  "Y":"BgABARK4BcQLhgMAERHnAvMGAKsEEhHnAgAUEgCsBOkC9AYREoYDABERWOEBUJsCUqICVtwBERI=",
  "Z":"BgABAQmAB8QLnwOBCaADAADBAusGAMgDggmhAwAAwgLGBgA=",
  "`":"BgABAQfqAd4JkQHmAQAOlgJCiAGpAgALiwIA",
  "c":"BgABAW3UA84GBQAFAQUABQEFAwMBBQMDAwMDAwUBAwMFAQUABQEHAAUAnQMABQIFAAUCBQQFAgMEBQQDBAMGAwQBBgMGAQYABgEGAPABABoMAMsCGw7tAQATABMCEwARAhMEEQIPBBEEDwQPBg8IDwYNCA0KDQoNCgsMCwwLDAkOCRAHDgcQBxIFEgUUBRQDFAEWAxgBGAAYAKQDABQCFAISBBQCEgYSBhAGEggQCBAIEAoQCg4MDAwODAwODAwKDgwQCg4IEAgQCBAIEAYSBhIGEgQSAhQCFAIUAOABABwOAM0CGQzbAQA=",
  "a":"BgABApoB8AYCxwF+BwkHCQcJCQkHBwkHBwcJBQkFBwUJBQkFCQMHBQkDCQMJAwcDCQEHAQkBBwEJAQcABwAHAQcABQAHAAUBBQAFABMAEwITAhEEEwQPBBEGDwgPCA0IDwoLCg0KCwwLDAsMCQ4JDgkOBw4HEAcQBRAFEAUSAxADEgESAxIBFAESABQAFAISAhQCEgQSBBIEEgYSBhIIEAgQChAIDgwODA4MDg4MDgwODBAMEAoSCBIKEggUCBQGFgYWBBgEGAIaAhoAcgAADgEMAQoBCgEIAwgDBgUEBQQFBAcCBwIHAgkCCQAJAKsCABcPAMwCHAvCAgAUABYBEgAUARIDFAMQAxIDEAUSBQ4FEAcOCRAJDAkOCwwLDA0MCwoNCg8IDwgPCA8GEQYRBhMEEwIXAhUCFwAZAIMGFwAKmQLqA38ATxchQwgnGiMwD1AMUDYAdg==",
  "b":"BgABAkqmBIIJGAAYARYBFgEUAxQDEgUSBRIFEAcQCQ4HDgkOCw4LDAsMDQoNCg0KDQgPBg8GDwYRBBEEEQQTBBECEwIVAhMAFQD/AgAZARcBFwEXAxUDEwUTBREFEQcPBw8JDwkNCQ0LDQsLCwsNCQ0JDQcPBw8HDwURAxEDEQMTAxMBEwMVARUAFQHPAwAUEgCWCxEY5gIAERkAowKCAQAJOvECESwrEn8AAJsEgAEALBISLgCeAw==",
  "d":"BgABAkryBgDLAXAREQ8NEQ0PDREJDwkRBw8FDwURAw8DDwERAw8BEQEPACMCHwQfCB0MGw4bEhcUFxgVGhEeDSANJAkmBSgDKgEuAIADABYCFAIUAhQCFAQUBBIGEgYSBhAIEAgQCBAKDgoODAwMDAwMDgoOCg4KEAgQCBIGEgYSBhQEFgQWBBYCGAIYAHwAAKQCERrmAgARFwCnCxcADOsCugJGMgDmA3sAKxERLQCfAwolHBUmBSQKBAA=",
  "e":"BgABAqMBigP+AgAJAgkCCQQHBAcGBwYFCAUIBQgDCgMIAQoDCAEKAQoACgAKAAoCCAIKAggECgQIBAgGCAYGBgQIBAoECAIKAAyiAgAAGQEXARcBFwMVBRMFEwURBxEHDwcPCQ8LDQkNCwsNCw0LDQkNBw8JDwcPBQ8FEQURAxEDEwMTAxMBFQAVARcALwIrBCkIJwwlDiESHxQbGBkaFR4TIA0iCyQJKAMqASwAggMAFAIUABIEFAISBBIEEgQSBhIGEAgQCBAIEAoODA4MDgwODgwQDBAKEAoSChIIFAgUCBYGGAQYBhoCGgQcAh4ALgEqAygFJgkkDSANHhEaFRgXFBsSHQ4fDCUIJwQpAi0AGQEXAxcDFQcTBRMJEQkPCw8LDQ0PDQsNDQ8LEQsRCxEJEwkTCRMJEwcTBxUHFQUVBRUHFQUVBRUHFwcVBRUHCs4BkAMfOEUURxEfMwBvbBhAGBwaBiA=",
  "h":"BgABAUHYBJAGAAYBBgAGAQYDBgEEAwYDBAMEBQQDAgUEBQIFAAUCBQB1AAC5BhIT5wIAFhQAlAsRGOYCABEZAKMCeAAYABgBFgEWARQDFAMSBRIFEgUQBxAJDgcOCQ4LDgsMCwwNCg0KDQoNCA8GDwYPBhEEEQQRBBMEEQITAhUCEwAVAO0FFhPnAgAUEgD+BQ==",
  "g":"BgABArkBkAeACQCNCw8ZERkRFxEVExMVERUPFQ8XDRcLGQkZBxsFGwUdAR0BDQALAA0ADQINAAsCDQANAg0CDQILAg0EDQINBA0GDQQNBg0EDQYNCA0GDwgNCA0IDQgPCg0KDwwNDA8MDw4PDqIB7gEQDRALEAkQCQ4JEAcOBw4FDgUOAwwFDgMMAQwBDAEMAQwACgEKAAoACAIIAAgCCAIGAggCBgIGBAYCBgQEAgYEAqIBAQADAAEBAwADAAMABQADAAUAAwAFAAMABQAFAAMABQA3ABMAEwIRAhMCEQQRBBEEEQYRBg8IDwgPCA0KDQoNCg0MCwwLDgsOCQ4JDgkQBxAHEgcSBRIDFAMWAxQBFgEYABgA/gIAFgIWAhQEFgQUBBIGFAgSCBIIEAoSChAKDgwODA4MDg4MDgwODA4KEAgQCBAIEgYSBhIEEgYSBBQCEgIUAhQCOgAQABABDgEQAQ4BEAMOAw4FDgUOBQwFDgcMBQ4HDAkMB4oBUBgACbsCzQYAnAR/AC0RES0AnQMSKy4RgAEA",
  "f":"BgABAUH8A6QJBwAHAAUABwEFAQcBBQEFAwUDBQMDAwMDAwUDAwMFAQUAwQHCAQAWEgDZAhUUwQEAAOMEFhftAgAWFADKCQoSChIKEAoQCg4KDgwOCgwMDAoKDAwMCgwIDAgMCAwIDAYOCAwEDgYMBA4GDAIOBA4CDgQOAg4CDgAOAg4ADgC2AQAcDgDRAhkQowEA",
  "i":"BgACAQlQABISALoIERLqAgAREQC5CBIR6QIAAWELyAoADgIOAgwEDgIKBgwGCgYKCAoGCAgICggIBggGCgYKBAoECgQMBAoCDAIMAgwCDAAMAAwADAEMAQoBDAMKAwoDCgUKBQgFCgUIBwgHCAcICQgJBgkECwQJBA0CCwANAA0ADQELAQ0BCwMJBQsFCQUJBwkFBwcHBwcJBQcFCQUJBQkDCQMLAwkBCwELAQsACwALAAsCCwILAgkCCwIJBAkECQQJBgcGCQYHCAcIBwgHCgUKBQwFCgMMAQwBDgEMAA4=",
  "j":"BgACAWFKyAoADgIOAgwEDgIKBgwGCgYKCAoGCAgICggIBggGCgYKBAoECgQMBAoCDAIMAgwCDAAMAAwADAEMAQoBDAMKAwoDCgUKBQgFCgUIBwgHCAcICQgJBgkECwQJBA0CCwANAA0ADQELAQ0BCwMJBQsFCQUJBwkFBwcHBwcJBQcFCQUJBQkDCQMLAwkBCwELAQsACwALAAsCCwILAgkCCwIJBAkECQQJBgcGCQYHCAcIBwgHCgUKBQwFCgMMAQwBDgEMAA4BO+YCnwwJEQkRCQ8JDwsNCQ0LDQkLCwsJCQsLCQkLBwsHCwcLBwsFCwcNAwsFDQMLBQ0BDQMNAQ0DDQENAQ0ADQENAA0AVwAbDQDSAhoPQgAIAAgABgAIAgYCCAIGAgYEBgQGBAQEBAQEBgQEBAYCBgC4CRES6gIAEREAowo=",
  "k":"BgABARKoA/QFIAC0AYoD5gIAjwK5BJICwwTfAgDDAbIDFwAAnwMSEeUCABISAJILERLmAgAREQCvBQ==",
  "n":"BgABAW1yggmQAU8GBAgEBgQGBgYCCAQGBAYEBgQIAgYECAQGAggEBgIIBAgCCAQIAggCCAIIAgoACAIKAAgCCgAKAgoADAAKAgwAFgAWARQAFAEUAxQDFAMSAxIFEgUQBRIHEAkOBxAJDgsOCwwLDA0MDQoPCA8IEQgRBhEGEwYVBBUEFQIXAhkCGQDtBRQR5QIAFBAA/AUACAEIAQYBCAMGBQQFBgUEBwQFBAcCBwIHAgcCCQIHAAcACQAHAQcABwMHAQUDBwMFAwUFBQUDBQEFAwcBBwAHAPkFEhHjAgASEgDwCBAA",
  "m":"BgABAZoBfoIJigFbDAwMCg4KDggOCA4IDgYQBhAGEAQQBBAEEAISAhACEgAmASQDJAciCyANHhEcFRwXDg4QDBAKEAwQCBAKEggSBhIGEgYSBBQEEgIUAhICFAAUABQBEgEUARIDEgMSAxIFEgUQBxAHEAcQBw4JDgkOCw4LDAsMDQoNCg8KDwgPCBEIEQYRBBMEEwQTAhMCFQAVAP0FEhHlAgASEgCCBgAIAQgBBgEGAwYFBgUEBQQHBAUEBwIHAgcCBwIJAAcABwAJAAcBBwEHAQUBBwMFAwUDBQMDBQMFAwUBBQEHAQcAgQYSEeUCABISAIIGAAgBCAEGAQYDBgUGBQQFBAcEBQQHAgcCBwIHAgkABwAHAAkABwEHAQcBBQEHAwUDBQMFAwMFAwUDBQEFAQcBBwCBBhIR5QIAEhIA8AgYAA==",
  "l":"BgABAQnAAwDrAgASFgDWCxEa6gIAERkA0wsUFw==",
  "y":"BgABAZ8BogeNAg8ZERkRFxEVExMVERUPFQ8XDRcLGQkZBxsFGwUdAR0BDQALAA0ADQINAAsCDQANAg0CDQILAg0EDQINBA0GDQQNBg0EDQYNCA0GDwgNCA0IDQgPCg0KDwwNDA8MDw4PDqIB7gEQDRALEAkQCQ4JEAcOBw4FDgUOAwwFDgMMAQwBDAEMAQwACgEKAAoACAIIAAgCCAIGAggCBgIGBAYCBgQEAgYEAqIBAQADAAEBAwADAAMABQADAAUAAwAFAAMABQAFAAMABQA3ABMAEwIRABECEwQRAg8EEQQPBBEGDwgNCA8IDQgNCg0MDQwLDAkOCw4JDgcQBxAHEgUSBRQFFAMWARgDGAEaABwA9AUTEuQCABEPAP8FAAUCBQAFAgUEBQIDBAUEAwQDBgMEAQYDBgEGAAgBBgCAAQAAvAYREuICABMPAP0K",
  "q":"BgABAmj0A4YJFgAWARQAEgESAxADEAMOAw4FDgUMBQ4HDgcOBwwJDgmeAU4A2QwWGesCABYaAN4DAwADAAMBAwADAAUAAwADAAMABQAFAAUABwAHAQcACQAVABUCFQATAhUCEwQRAhMEEQQRBhEGDwgPCA8IDQoNDA0MCwwLDgkOCRAJEAkQBxIHEgUUBRYDFgMYARoBGgAcAP4CABYCFgIWBBYEFAQSBhQIEggSCBAKEgoQDA4MDgwODg4ODBAMDgwQChIIEAoSCBIGEgYUBhQEFAQWAhYCFgIWAApbkQYSKy4ReAAAjARTEjkRHykJMwDvAg==",
  "p":"BgABAmiCBIYJFgAWARYBFAEWAxQDEgUUBRIFEgcSBxAJEAkQCQ4LDgsOCwwNDA0KDwoPCg8IEQgRCBEGEwQTBhMCFQQVAhUAFQD9AgAbARkBFwMXAxcDEwUTBxMHEQcRCQ8JDQsNCw0LCw0LDQkPCQ0JDwURBxEFEQURAxMDEQMTARUBEwEVARUBFQAJAAcABwAFAAcABQAFAAMAAwADAAUAAwIDAAMAAwIDAADdAxYZ6wIAFhoA2gyeAU0OCgwIDgoMCA4GDgYMBg4GDgQQBBAEEgQUAhQCFgIWAApcoQMJNB8qNxJVEQCLBHgALhISLADwAg==",
  "o":"BgABAoMB8gOICRYAFgEWARQBFgMUAxIDFAUSBRIHEgcQBxAJEAkOCw4LDgsMDQwNCg8KDwoPCg8IEQgRBhMGEwQTBBMCFQIVABcAiwMAFwEVARUDEwMTAxMFEwcRBxEHDwkPCQ8LDQsNCw0NCw0LDwkNCw8HEQkPBxEHEQcRBRMFEwMTAxUDFQEVABUAFQAVAhUCFQITBBMEEwYTBhEGEQgRCA8KDwoPCg0KDQwNDAsOCw4JDgkQCRAJEgcSBxIFFAUUAxQDFgEWARYAFgCMAwAYAhYCFgQUBBQEFAYUCBIIEggQChAKEAwODA4MDg4MDgwQCg4KEgoQChIIEggSBhQGEgYUBBYEFAIWAhYCFgALYv0CHTZBFEMRHTcAjwMcNUITQhIiOACQAw==",
  "r":"BgACAQRigAkQAA8AAAABShAAhAFXDAwODAwKDgoOCBAIDgYQBhAEEAQQBBAEEAISABACEAAQAA4BEAAQARADEAEQAxADEAUSBRIHFAcUCxQLFA0WDVJFsQHzAQsMDQwLCgkICwgLCAkGCQYJBAkGBwIJBAcCBwQHAAcCBwAFAgcABQAHAQUABQEFAQUBBQEDAQUBAwMDAQMDAwEAmwYSEeMCABISAO4IEAA=",
  "u":"BgABAV2KBwGPAVANCQsHDQcNBw0FCwUNBQ0FDQMPAw8DEQMTARMBFQEVABUAFQITABMEEwITBBMEEQQRBhEGDwYRCA8KDQgPCg0MDQwLDAsOCRALDgcQBxIHEgUUBRQFFAMWAxgBGAEYARoA7gUTEuYCABMPAPsFAAcCBwIFBAcCBQYDBgUGAwgDBgMIAQgBCAEIAQoBCAAIAAoACAIIAggCCAIGBAgEBgQGBgYGBAYCBgQIAggACAD6BRES5AIAEREA7wgPAA==",
  "s":"BgABAasC/gLwBQoDCgMMBQ4DDgUOBRAFEAUSBRAHEgcQCRIJEAkSCxALEAsQDRANDg0ODw4PDA8MDwoRChEIEwYTBBcCFQIXABkBGQEXAxcFFQUTBRMHEwcRCREJDwkNCQ8LDQ0LCwsNCw0JDQkPBw8HDwUPBREDEQMRAREDEQETABEBEwARABMADwIRABECEQIRBBMCEwQVBBUEFQYVBhMIFwgVChUKFQxgsAIIAwYDCAMKAQgDCAMKAQoDCgEKAwoBCgMKAQwDCgEKAwoBDAMKAQoBCgEMAQoACgEKAAoBCgAKAQgACgAIAQgABgoECAIKAgoCCgAMAQoBDAUEBwIHBAcEBwIHBAkECQQJBAkECQYLBAkGCwYJBgsGCwYJCAsGCwgJBgsICQgLCAkICwgJCgkKCQoJCgcKCQwHDAcMBwwFDAcMAw4FDAMOAw4BDgMQARAAEAESABIAEgIQAg4CDgIOBA4CDgQMBAwEDAQMBgoECgYKBgoGCgYIBggGCAgIBggGBgYIBgYGBgYGBgYGBAgGBgQIBAYECAQQChIIEggSBhIEEgQSBBQCFAISABQAEgASABIAEgESARIBEAEQAxIDDgMQAxADDgUOBQwDDAMMAwoDCAMIAQYBe6cCAwIDAgUAAwIFAgUCBwIFAgcCBQIHAgUCBwIHAAUCBwIHAgUABwIHAgcABQIHAAcCBwAFAgUABQIFAAUABQIDAAEAAQABAQEAAQEBAQEBAQEBAQEDAQEAAwEBAQMAAwEDAAMBAwADAQMAAwABAQMAAwADAAEAAwIBAAMCAQQDAgE=",
  "t":"BgABAUe8BLACWAAaEADRAhsOaQANAA0ADwINAA0CDQANAg0CDQINBA0CCwYNBA0GCwYNBgsIDQgLCAsKCwgJDAsKCQwJDAkOCQ4HEAcSBxIHEgUUAOAEawAVEQDWAhYTbAAAygIVFOYCABUXAMUCogEAFhQA1QIVEqEBAADzAwIFBAMEBQQDBAMEAwYDBgMGAwYBCAEGAQgBBgEIAAgA",
  "w":"BgABARz8BsAEINYCKNgBERLuAgARD+8B3QgSEc0CABQSW7YCV7UCFBHJAgASEpMC3AgREvACABERmAHxBDDaAVeYAxES7gIAEREo1QE81wIIAA==",
  "z":"BgABAQ6cA9AGuQIAFw8AzAIaC9QFAAAr9wKjBuACABYQAMsCGQyZBgCaA9AG"
   }';
BEGIN

  IF font IS NULL THEN
    font := font_default;
  END IF;

  -- For character spacing, use m as guide size
  geom := ST_GeomFromTWKB(decode(font->>'m', 'base64'));
  m_width := ST_XMax(geom) - ST_XMin(geom);
  spacing := m_width / 12;

  letterarray := regexp_split_to_array(replace(letters, ' ', E'\t'), E'');
  FOREACH letter IN ARRAY letterarray
  LOOP
    geom := ST_GeomFromTWKB(decode(font->>(letter), 'base64'));
    -- Chars are not already zeroed out, so do it now
    geom := ST_Translate(geom, -1 * ST_XMin(geom), 0.0);
    -- unknown characters are treated as spaces
    IF geom IS NULL THEN
      -- spaces are a "quarter m" in width
      width := m_width / 3.5;
    ELSE
      width := (ST_XMax(geom) - ST_XMin(geom));
    END IF;
    geom := ST_Translate(geom, position, 0.0);
    -- Tighten up spacing when characters have a large gap
    -- between them like Yo or To
    adjustment := 0.0;
    IF prevgeom IS NOT NULL AND geom IS NOT NULL THEN
      dist = ST_Distance(prevgeom, geom);
      IF dist > spacing THEN
        adjustment = spacing - dist;
        geom := ST_Translate(geom, adjustment, 0.0);
      END IF;
    END IF;
    prevgeom := geom;
    position := position + width + spacing + adjustment;
    wordarr := array_append(wordarr, geom);
  END LOOP;
  -- apply the start point and scaling options
  wordgeom := ST_CollectionExtract(ST_Collect(wordarr));
  wordgeom := ST_Scale(wordgeom,
                text_height/font_default_height,
                text_height/font_default_height);
  return wordgeom;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.st_linecrossingdirection(line1 geometry, line2 geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$ST_LineCrossingDirection$function$
;

CREATE OR REPLACE FUNCTION public.st_lineextend(geom geometry, distance_forward double precision, distance_backward double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geometry_line_extend$function$
;

CREATE OR REPLACE FUNCTION public.st_linefromencodedpolyline(txtin text, nprecision integer DEFAULT 5)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$line_from_encoded_polyline$function$
;

CREATE OR REPLACE FUNCTION public.st_linefrommultipoint(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_line_from_mpoint$function$
;

CREATE OR REPLACE FUNCTION public.st_linefromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_LineString'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_linefromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_LineString'
	THEN public.ST_GeomFromText($1,$2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_linefromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_LineString'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_linefromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_LineString'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoint(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_line_interpolate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoint(geography, double precision, use_spheroid boolean DEFAULT true)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_line_interpolate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoint(text, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_LineInterpolatePoint($1::public.geometry, $2);  $function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoints(geometry, double precision, repeat boolean DEFAULT true)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_line_interpolate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoints(geography, double precision, use_spheroid boolean DEFAULT true, repeat boolean DEFAULT true)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_line_interpolate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_lineinterpolatepoints(text, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_LineInterpolatePoints($1::public.geometry, $2);  $function$
;

CREATE OR REPLACE FUNCTION public.st_linelocatepoint(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_line_locate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_linelocatepoint(geography, geography, use_spheroid boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_line_locate_point$function$
;

CREATE OR REPLACE FUNCTION public.st_linelocatepoint(text, text)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_LineLocatePoint($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_linemerge(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$linemerge$function$
;

CREATE OR REPLACE FUNCTION public.st_linemerge(geometry, boolean)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$linemerge$function$
;

CREATE OR REPLACE FUNCTION public.st_linestringfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_LineString'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_linestringfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_LineString'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_linesubstring(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_line_substring$function$
;

CREATE OR REPLACE FUNCTION public.st_linesubstring(geography, double precision, double precision)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_line_substring$function$
;

CREATE OR REPLACE FUNCTION public.st_linesubstring(text, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_LineSubstring($1::public.geometry, $2, $3);  $function$
;

CREATE OR REPLACE FUNCTION public.st_linetocurve(geometry geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_line_desegmentize$function$
;

CREATE OR REPLACE FUNCTION public.st_locatealong(geometry geometry, measure double precision, leftrightoffset double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_LocateAlong$function$
;

CREATE OR REPLACE FUNCTION public.st_locatebetween(geometry geometry, frommeasure double precision, tomeasure double precision, leftrightoffset double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_LocateBetween$function$
;

CREATE OR REPLACE FUNCTION public.st_locatebetweenelevations(geometry geometry, fromelevation double precision, toelevation double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_LocateBetweenElevations$function$
;

CREATE OR REPLACE FUNCTION public.st_longestline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public._ST_LongestLine(public.ST_ConvexHull($1), public.ST_ConvexHull($2))$function$
;

CREATE OR REPLACE FUNCTION public.st_m(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_m_point$function$
;

CREATE OR REPLACE FUNCTION public.st_makebox2d(geom1 geometry, geom2 geometry)
 RETURNS box2d
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX2D_construct$function$
;

CREATE OR REPLACE FUNCTION public.st_makeenvelope(double precision, double precision, double precision, double precision, integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_MakeEnvelope$function$
;

CREATE OR REPLACE FUNCTION public.st_makeline(geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makeline_garray$function$
;

CREATE OR REPLACE FUNCTION public.st_makeline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makeline$function$
;

CREATE OR REPLACE FUNCTION public.st_makepoint(double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoint$function$
;

CREATE OR REPLACE FUNCTION public.st_makepoint(double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoint$function$
;

CREATE OR REPLACE FUNCTION public.st_makepoint(double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoint$function$
;

CREATE OR REPLACE FUNCTION public.st_makepointm(double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoint3dm$function$
;

CREATE OR REPLACE FUNCTION public.st_makepolygon(geometry, geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoly$function$
;

CREATE OR REPLACE FUNCTION public.st_makepolygon(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoly$function$
;

CREATE OR REPLACE FUNCTION public.st_makevalid(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MakeValid$function$
;

CREATE OR REPLACE FUNCTION public.st_makevalid(geom geometry, params text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MakeValid$function$
;

CREATE OR REPLACE FUNCTION public.st_maxdistance(geom1 geometry, geom2 geometry)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public._ST_MaxDistance(public.ST_ConvexHull($1), public.ST_ConvexHull($2))$function$
;

CREATE OR REPLACE FUNCTION public.st_maximuminscribedcircle(geometry, OUT center geometry, OUT nearest geometry, OUT radius double precision)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MaximumInscribedCircle$function$
;

CREATE OR REPLACE FUNCTION public.st_memsize(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_mem_size$function$
;

CREATE OR REPLACE FUNCTION public.st_minimumboundingcircle(inputgeom geometry, segs_per_quarter integer DEFAULT 48)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MinimumBoundingCircle$function$
;

CREATE OR REPLACE FUNCTION public.st_minimumboundingradius(geometry, OUT center geometry, OUT radius double precision)
 RETURNS record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MinimumBoundingRadius$function$
;

CREATE OR REPLACE FUNCTION public.st_minimumclearance(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MinimumClearance$function$
;

CREATE OR REPLACE FUNCTION public.st_minimumclearanceline(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_MinimumClearanceLine$function$
;

CREATE OR REPLACE FUNCTION public.st_mlinefromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE
	WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_MultiLineString'
	THEN public.ST_GeomFromText($1,$2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mlinefromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_MultiLineString'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mlinefromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_MultiLineString'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mlinefromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiLineString'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpointfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_MultiPoint'
	THEN ST_GeomFromText($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpointfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_MultiPoint'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpointfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_MultiPoint'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpointfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiPoint'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpolyfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromText($1,$2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpolyfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpolyfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_mpolyfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multi(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_force_multi$function$
;

CREATE OR REPLACE FUNCTION public.st_multilinefromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiLineString'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multilinestringfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_MLineFromText($1)$function$
;

CREATE OR REPLACE FUNCTION public.st_multilinestringfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_MLineFromText($1, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_multipointfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_MPointFromText($1)$function$
;

CREATE OR REPLACE FUNCTION public.st_multipointfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1,$2)) = 'ST_MultiPoint'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multipointfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiPoint'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multipolyfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multipolyfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_MultiPolygon'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_multipolygonfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_MPolyFromText($1, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_multipolygonfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_MPolyFromText($1)$function$
;

CREATE OR REPLACE FUNCTION public.st_ndims(geometry)
 RETURNS smallint
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_ndims$function$
;

CREATE OR REPLACE FUNCTION public.st_node(g geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Node$function$
;

CREATE OR REPLACE FUNCTION public.st_normalize(geom geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_Normalize$function$
;

CREATE OR REPLACE FUNCTION public.st_npoints(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_npoints$function$
;

CREATE OR REPLACE FUNCTION public.st_nrings(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_nrings$function$
;

CREATE OR REPLACE FUNCTION public.st_numcurves(geometry geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_NumCurves$function$
;

CREATE OR REPLACE FUNCTION public.st_numgeometries(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_numgeometries_collection$function$
;

CREATE OR REPLACE FUNCTION public.st_numinteriorring(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_numinteriorrings_polygon$function$
;

CREATE OR REPLACE FUNCTION public.st_numinteriorrings(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_numinteriorrings_polygon$function$
;

CREATE OR REPLACE FUNCTION public.st_numpatches(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_numpatches$function$
;

CREATE OR REPLACE FUNCTION public.st_numpoints(geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_numpoints_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_offsetcurve(line geometry, distance double precision, params text DEFAULT ''::text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_OffsetCurve$function$
;

CREATE OR REPLACE FUNCTION public.st_orderingequals(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$LWGEOM_same$function$
;

CREATE OR REPLACE FUNCTION public.st_orientedenvelope(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_OrientedEnvelope$function$
;

CREATE OR REPLACE FUNCTION public.st_overlaps(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$overlaps$function$
;

CREATE OR REPLACE FUNCTION public.st_patchn(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_patchn$function$
;

CREATE OR REPLACE FUNCTION public.st_perimeter(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_perimeter2d_poly$function$
;

CREATE OR REPLACE FUNCTION public.st_perimeter(geog geography, use_spheroid boolean DEFAULT true)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_perimeter$function$
;

CREATE OR REPLACE FUNCTION public.st_perimeter2d(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_perimeter2d_poly$function$
;

CREATE OR REPLACE FUNCTION public.st_point(double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_makepoint$function$
;

CREATE OR REPLACE FUNCTION public.st_point(double precision, double precision, srid integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Point$function$
;

CREATE OR REPLACE FUNCTION public.st_pointfromgeohash(text, integer DEFAULT NULL::integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 50
AS '$libdir/postgis-3', $function$point_from_geohash$function$
;

CREATE OR REPLACE FUNCTION public.st_pointfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_Point'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_pointfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_Point'
	THEN public.ST_GeomFromText($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_pointfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_Point'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_pointfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_Point'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_pointinsidecircle(geometry, double precision, double precision, double precision)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_inside_circle_point$function$
;

CREATE OR REPLACE FUNCTION public.st_pointm(xcoordinate double precision, ycoordinate double precision, mcoordinate double precision, srid integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_PointM$function$
;

CREATE OR REPLACE FUNCTION public.st_pointn(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_pointn_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_pointonsurface(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$pointonsurface$function$
;

CREATE OR REPLACE FUNCTION public.st_points(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_Points$function$
;

CREATE OR REPLACE FUNCTION public.st_pointz(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, srid integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_PointZ$function$
;

CREATE OR REPLACE FUNCTION public.st_pointzm(xcoordinate double precision, ycoordinate double precision, zcoordinate double precision, mcoordinate double precision, srid integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_PointZM$function$
;

CREATE OR REPLACE FUNCTION public.st_polyfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1)) = 'ST_Polygon'
	THEN public.ST_GeomFromText($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polyfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromText($1, $2)) = 'ST_Polygon'
	THEN public.ST_GeomFromText($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polyfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1, $2)) = 'ST_Polygon'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polyfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_Polygon'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polygon(geometry, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT public.ST_SetSRID(public.ST_MakePolygon($1), $2)
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polygonfromtext(text, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_PolyFromText($1, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_polygonfromtext(text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS $function$SELECT public.ST_PolyFromText($1)$function$
;

CREATE OR REPLACE FUNCTION public.st_polygonfromwkb(bytea, integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1,$2)) = 'ST_Polygon'
	THEN public.ST_GeomFromWKB($1, $2)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polygonfromwkb(bytea)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$
	SELECT CASE WHEN public.ST_GeometryType(public.ST_GeomFromWKB($1)) = 'ST_Polygon'
	THEN public.ST_GeomFromWKB($1)
	ELSE NULL END
	$function$
;

CREATE OR REPLACE FUNCTION public.st_polygonize(geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$polygonize_garray$function$
;

CREATE OR REPLACE FUNCTION public.st_project(geom1 geometry, distance double precision, azimuth double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geometry_project_direction$function$
;

CREATE OR REPLACE FUNCTION public.st_project(geom1 geometry, geom2 geometry, distance double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$geometry_project_geometry$function$
;

CREATE OR REPLACE FUNCTION public.st_project(geog geography, distance double precision, azimuth double precision)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$geography_project$function$
;

CREATE OR REPLACE FUNCTION public.st_project(geog_from geography, geog_to geography, distance double precision)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_project_geography$function$
;

CREATE OR REPLACE FUNCTION public.st_quantizecoordinates(g geometry, prec_x integer, prec_y integer DEFAULT NULL::integer, prec_z integer DEFAULT NULL::integer, prec_m integer DEFAULT NULL::integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE COST 250
AS '$libdir/postgis-3', $function$ST_QuantizeCoordinates$function$
;

CREATE OR REPLACE FUNCTION public.st_reduceprecision(geom geometry, gridsize double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_ReducePrecision$function$
;

CREATE OR REPLACE FUNCTION public.st_relate(geom1 geometry, geom2 geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$relate_full$function$
;

CREATE OR REPLACE FUNCTION public.st_relate(geom1 geometry, geom2 geometry, integer)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$relate_full$function$
;

CREATE OR REPLACE FUNCTION public.st_relate(geom1 geometry, geom2 geometry, text)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$relate_pattern$function$
;

CREATE OR REPLACE FUNCTION public.st_relatematch(text, text)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_RelateMatch$function$
;

CREATE OR REPLACE FUNCTION public.st_removeirrelevantpointsforview(geometry, box2d, boolean DEFAULT false)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_RemoveIrrelevantPointsForView$function$
;

CREATE OR REPLACE FUNCTION public.st_removepoint(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_removepoint$function$
;

CREATE OR REPLACE FUNCTION public.st_removerepeatedpoints(geom geometry, tolerance double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_RemoveRepeatedPoints$function$
;

CREATE OR REPLACE FUNCTION public.st_removesmallparts(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_RemoveSmallParts$function$
;

CREATE OR REPLACE FUNCTION public.st_reverse(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_reverse$function$
;

CREATE OR REPLACE FUNCTION public.st_rotate(geometry, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  cos($2), -sin($2), 0,  sin($2), cos($2), 0,  0, 0, 1,  0, 0, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_rotate(geometry, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  cos($2), -sin($2), 0,  sin($2),  cos($2), 0, 0, 0, 1,	$3 - cos($2) * $3 + sin($2) * $4, $4 - sin($2) * $3 - cos($2) * $4, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_rotate(geometry, double precision, geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  cos($2), -sin($2), 0,  sin($2),  cos($2), 0, 0, 0, 1, public.ST_X($3) - cos($2) * public.ST_X($3) + sin($2) * public.ST_Y($3), public.ST_Y($3) - sin($2) * public.ST_X($3) - cos($2) * public.ST_Y($3), 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_rotatex(geometry, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1, 1, 0, 0, 0, cos($2), -sin($2), 0, sin($2), cos($2), 0, 0, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_rotatey(geometry, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  cos($2), 0, sin($2),  0, 1, 0,  -sin($2), 0, cos($2), 0,  0, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_rotatez(geometry, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Rotate($1, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_scale(geometry, geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Scale$function$
;

CREATE OR REPLACE FUNCTION public.st_scale(geometry, geometry, origin geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Scale$function$
;

CREATE OR REPLACE FUNCTION public.st_scale(geometry, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Scale($1, public.ST_MakePoint($2, $3, $4))$function$
;

CREATE OR REPLACE FUNCTION public.st_scale(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Scale($1, $2, $3, 1)$function$
;

CREATE OR REPLACE FUNCTION public.st_scroll(geometry, geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Scroll$function$
;

CREATE OR REPLACE FUNCTION public.st_segmentize(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_segmentize2d$function$
;

CREATE OR REPLACE FUNCTION public.st_segmentize(geog geography, max_segment_length double precision)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$geography_segmentize$function$
;

CREATE OR REPLACE FUNCTION public.st_seteffectivearea(geometry, double precision DEFAULT '-1'::integer, integer DEFAULT 1)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_SetEffectiveArea$function$
;

CREATE OR REPLACE FUNCTION public.st_setpoint(geometry, integer, geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_setpoint_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_setsrid(geom geometry, srid integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_set_srid$function$
;

CREATE OR REPLACE FUNCTION public.st_setsrid(geog geography, srid integer)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_set_srid$function$
;

CREATE OR REPLACE FUNCTION public.st_sharedpaths(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_SharedPaths$function$
;

CREATE OR REPLACE FUNCTION public.st_shiftlongitude(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_longitude_shift$function$
;

CREATE OR REPLACE FUNCTION public.st_shortestline(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_shortestline2d$function$
;

CREATE OR REPLACE FUNCTION public.st_shortestline(geography, geography, use_spheroid boolean DEFAULT true)
 RETURNS geography
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$geography_shortestline$function$
;

CREATE OR REPLACE FUNCTION public.st_shortestline(text, text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public.ST_ShortestLine($1::public.geometry, $2::public.geometry);  $function$
;

CREATE OR REPLACE FUNCTION public.st_simplify(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_simplify2d$function$
;

CREATE OR REPLACE FUNCTION public.st_simplify(geometry, double precision, boolean)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_simplify2d$function$
;

CREATE OR REPLACE FUNCTION public.st_simplifypolygonhull(geom geometry, vertex_fraction double precision, is_outer boolean DEFAULT true)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_SimplifyPolygonHull$function$
;

CREATE OR REPLACE FUNCTION public.st_simplifypreservetopology(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$topologypreservesimplify$function$
;

CREATE OR REPLACE FUNCTION public.st_simplifyvw(geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$LWGEOM_SetEffectiveArea$function$
;

CREATE OR REPLACE FUNCTION public.st_snap(geom1 geometry, geom2 geometry, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Snap$function$
;

CREATE OR REPLACE FUNCTION public.st_snaptogrid(geometry, double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_snaptogrid$function$
;

CREATE OR REPLACE FUNCTION public.st_snaptogrid(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_SnapToGrid($1, 0, 0, $2, $3)$function$
;

CREATE OR REPLACE FUNCTION public.st_snaptogrid(geometry, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_SnapToGrid($1, 0, 0, $2, $2)$function$
;

CREATE OR REPLACE FUNCTION public.st_snaptogrid(geom1 geometry, geom2 geometry, double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_snaptogrid_pointoff$function$
;

CREATE OR REPLACE FUNCTION public.st_split(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Split$function$
;

CREATE OR REPLACE FUNCTION public.st_square(size double precision, cell_i integer, cell_j integer, origin geometry DEFAULT '010100000000000000000000000000000000000000'::geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_Square$function$
;

CREATE OR REPLACE FUNCTION public.st_squaregrid(size double precision, bounds geometry, OUT geom geometry, OUT i integer, OUT j integer)
 RETURNS SETOF record
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$ST_ShapeGrid$function$
;

CREATE OR REPLACE FUNCTION public.st_srid(geom geometry)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_get_srid$function$
;

CREATE OR REPLACE FUNCTION public.st_srid(geog geography)
 RETURNS integer
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_get_srid$function$
;

CREATE OR REPLACE FUNCTION public.st_startpoint(geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_startpoint_linestring$function$
;

CREATE OR REPLACE FUNCTION public.st_subdivide(geom geometry, maxvertices integer DEFAULT 256, gridsize double precision DEFAULT '-1.0'::numeric)
 RETURNS SETOF geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Subdivide$function$
;

CREATE OR REPLACE FUNCTION public.st_summary(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_summary$function$
;

CREATE OR REPLACE FUNCTION public.st_summary(geography)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_summary$function$
;

CREATE OR REPLACE FUNCTION public.st_swapordinates(geom geometry, ords cstring)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_SwapOrdinates$function$
;

CREATE OR REPLACE FUNCTION public.st_symdifference(geom1 geometry, geom2 geometry, gridsize double precision DEFAULT '-1.0'::numeric)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_SymDifference$function$
;

CREATE OR REPLACE FUNCTION public.st_symmetricdifference(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE sql
AS $function$SELECT public.ST_SymDifference(geom1, geom2, -1.0);$function$
;

CREATE OR REPLACE FUNCTION public.st_tileenvelope(zoom integer, x integer, y integer, bounds geometry DEFAULT '0102000020110F00000200000093107C45F81B73C193107C45F81B73C193107C45F81B734193107C45F81B7341'::geometry, margin double precision DEFAULT 0.0)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_TileEnvelope$function$
;

CREATE OR REPLACE FUNCTION public.st_touches(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$touches$function$
;

CREATE OR REPLACE FUNCTION public.st_transform(geometry, integer)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$transform$function$
;

CREATE OR REPLACE FUNCTION public.st_transform(geom geometry, to_proj text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public.postgis_transform_geometry($1, proj4text, $2, 0)
	FROM public.spatial_ref_sys WHERE srid=public.ST_SRID($1);$function$
;

CREATE OR REPLACE FUNCTION public.st_transform(geom geometry, from_proj text, to_proj text)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public.postgis_transform_geometry($1, $2, $3, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_transform(geom geometry, from_proj text, to_srid integer)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public.postgis_transform_geometry($1, $2, proj4text, $3)
	FROM public.spatial_ref_sys WHERE srid=$3;$function$
;

CREATE OR REPLACE FUNCTION public.st_transformpipeline(geom geometry, pipeline text, to_srid integer DEFAULT 0)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS $function$SELECT public.postgis_transform_pipeline_geometry($1, $2, TRUE, $3)$function$
;

CREATE OR REPLACE FUNCTION public.st_translate(geometry, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1, 1, 0, 0, 0, 1, 0, 0, 0, 1, $2, $3, $4)$function$
;

CREATE OR REPLACE FUNCTION public.st_translate(geometry, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Translate($1, $2, $3, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_transscale(geometry, double precision, double precision, double precision, double precision)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS $function$SELECT public.ST_Affine($1,  $4, 0, 0,  0, $5, 0,
		0, 0, 1,  $2 * $4, $3 * $5, 0)$function$
;

CREATE OR REPLACE FUNCTION public.st_triangulatepolygon(g1 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_TriangulatePolygon$function$
;

CREATE OR REPLACE FUNCTION public.st_unaryunion(geometry, gridsize double precision DEFAULT '-1.0'::numeric)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_UnaryUnion$function$
;

CREATE OR REPLACE FUNCTION public.st_union(geom1 geometry, geom2 geometry)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Union$function$
;

CREATE OR REPLACE FUNCTION public.st_union(geom1 geometry, geom2 geometry, gridsize double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$ST_Union$function$
;

CREATE OR REPLACE FUNCTION public.st_union(geometry[])
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000
AS '$libdir/postgis-3', $function$pgis_union_geometry_array$function$
;

CREATE OR REPLACE FUNCTION public.st_voronoilines(g1 geometry, tolerance double precision DEFAULT 0.0, extend_to geometry DEFAULT NULL::geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_Voronoi(g1, extend_to, tolerance, false) $function$
;

CREATE OR REPLACE FUNCTION public.st_voronoipolygons(g1 geometry, tolerance double precision DEFAULT 0.0, extend_to geometry DEFAULT NULL::geometry)
 RETURNS geometry
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE
AS $function$ SELECT public._ST_Voronoi(g1, extend_to, tolerance, true) $function$
;

CREATE OR REPLACE FUNCTION public.st_within(geom1 geometry, geom2 geometry)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 5000 SUPPORT postgis_index_supportfn
AS '$libdir/postgis-3', $function$within$function$
;

CREATE OR REPLACE FUNCTION public.st_wkbtosql(wkb bytea)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_from_WKB$function$
;

CREATE OR REPLACE FUNCTION public.st_wkttosql(text)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 250
AS '$libdir/postgis-3', $function$LWGEOM_from_text$function$
;

CREATE OR REPLACE FUNCTION public.st_wrapx(geom geometry, wrap double precision, move double precision)
 RETURNS geometry
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$ST_WrapX$function$
;

CREATE OR REPLACE FUNCTION public.st_x(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_x_point$function$
;

CREATE OR REPLACE FUNCTION public.st_xmax(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_xmax$function$
;

CREATE OR REPLACE FUNCTION public.st_xmin(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_xmin$function$
;

CREATE OR REPLACE FUNCTION public.st_y(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_y_point$function$
;

CREATE OR REPLACE FUNCTION public.st_ymax(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_ymax$function$
;

CREATE OR REPLACE FUNCTION public.st_ymin(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_ymin$function$
;

CREATE OR REPLACE FUNCTION public.st_z(geometry)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_z_point$function$
;

CREATE OR REPLACE FUNCTION public.st_zmax(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_zmax$function$
;

CREATE OR REPLACE FUNCTION public.st_zmflag(geometry)
 RETURNS smallint
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$LWGEOM_zmflag$function$
;

CREATE OR REPLACE FUNCTION public.st_zmin(box3d)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/postgis-3', $function$BOX3D_zmin$function$
;

CREATE OR REPLACE FUNCTION public.strict_word_similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity$function$
;

CREATE OR REPLACE FUNCTION public.strict_word_similarity_commutator_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_commutator_op$function$
;

CREATE OR REPLACE FUNCTION public.strict_word_similarity_dist_commutator_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_dist_commutator_op$function$
;

CREATE OR REPLACE FUNCTION public.strict_word_similarity_dist_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_dist_op$function$
;

CREATE OR REPLACE FUNCTION public.strict_word_similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_op$function$
;

CREATE OR REPLACE FUNCTION public.sync_wf_transition_steps()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
      -- FROM sync
      IF NEW.from_step_id IS NULL AND NEW.from_step_template_id IS NOT NULL THEN
        NEW.from_step_id := NEW.from_step_template_id;
      ELSIF NEW.from_step_template_id IS NULL AND NEW.from_step_id IS NOT NULL THEN
        NEW.from_step_template_id := NEW.from_step_id;
      END IF;

      -- TO sync
      IF NEW.to_step_id IS NULL AND NEW.to_step_template_id IS NOT NULL THEN
        NEW.to_step_id := NEW.to_step_template_id;
      ELSIF NEW.to_step_template_id IS NULL AND NEW.to_step_id IS NOT NULL THEN
        NEW.to_step_template_id := NEW.to_step_id;
      END IF;

      RETURN NEW;
    END
    $function$
;

CREATE OR REPLACE FUNCTION public.sync_workitem_project()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.work_item_id IS NULL AND NEW.project_id IS NOT NULL THEN
    NEW.work_item_id := NEW.project_id;  -- giữ tương thích tạm thời
  ELSIF NEW.project_id IS NULL AND NEW.work_item_id IS NOT NULL THEN
    NEW.project_id := NEW.work_item_id;
  END IF;
  RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.text(geometry)
 RETURNS text
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT COST 50
AS '$libdir/postgis-3', $function$LWGEOM_to_text$function$
;

CREATE OR REPLACE FUNCTION public.trg_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END$function$
;

CREATE OR REPLACE FUNCTION public.trg_wi_cat_set_level_biu()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.level := public.f_wi_cat_compute_level(NEW.id, NEW.parent_id);
  RETURN NEW;
END$function$
;

CREATE OR REPLACE FUNCTION public.unaccent(regdictionary, text)
 RETURNS text
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/unaccent', $function$unaccent_dict$function$
;

CREATE OR REPLACE FUNCTION public.unaccent(text)
 RETURNS text
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/unaccent', $function$unaccent_dict$function$
;

CREATE OR REPLACE FUNCTION public.unaccent_init(internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/unaccent', $function$unaccent_init$function$
;

CREATE OR REPLACE FUNCTION public.unaccent_lexize(internal, internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 PARALLEL SAFE
AS '$libdir/unaccent', $function$unaccent_lexize$function$
;

CREATE OR REPLACE FUNCTION public.update_progress_tasks()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Nếu task gắn package
    IF NEW.package_id IS NOT NULL THEN
        UPDATE packages pk
        SET progress = (SELECT AVG(CASE WHEN t.status = 'done' THEN 100 ELSE 0 END) FROM tasks t WHERE t.package_id = pk.id AND t.is_deleted = false)
        WHERE pk.id = NEW.package_id;
        
        -- Cascade lên project từ package
        UPDATE projects p
        SET progress = (SELECT AVG(pk.progress) FROM packages pk WHERE pk.project_id = p.id)
        WHERE p.id = (SELECT pk.project_id FROM packages pk WHERE pk.id = NEW.package_id);
    ELSE
        -- Nếu task direct project (không package)
        UPDATE projects p
        SET progress = (SELECT AVG(CASE WHEN t.status = 'done' THEN 100 ELSE 0 END) FROM tasks t WHERE t.project_id = p.id AND t.is_deleted = false)
        WHERE p.id = NEW.project_id;
    END IF;
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.updategeometrysrid(catalogn_name character varying, schema_name character varying, table_name character varying, column_name character varying, new_srid_in integer)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	myrec RECORD;
	okay boolean;
	cname varchar;
	real_schema name;
	unknown_srid integer;
	new_srid integer := new_srid_in;

BEGIN

	-- Find, check or fix schema_name
	IF ( schema_name != '' ) THEN
		okay = false;

		FOR myrec IN SELECT nspname FROM pg_namespace WHERE text(nspname) = schema_name LOOP
			okay := true;
		END LOOP;

		IF ( okay <> true ) THEN
			RAISE EXCEPTION 'Invalid schema name';
		ELSE
			real_schema = schema_name;
		END IF;
	ELSE
		SELECT INTO real_schema current_schema()::text;
	END IF;

	-- Ensure that column_name is in geometry_columns
	okay = false;
	FOR myrec IN SELECT type, coord_dimension FROM public.geometry_columns WHERE f_table_schema = text(real_schema) and f_table_name = table_name and f_geometry_column = column_name LOOP
		okay := true;
	END LOOP;
	IF (NOT okay) THEN
		RAISE EXCEPTION 'column not found in geometry_columns table';
		RETURN false;
	END IF;

	-- Ensure that new_srid is valid
	IF ( new_srid > 0 ) THEN
		IF ( SELECT count(*) = 0 from public.spatial_ref_sys where srid = new_srid ) THEN
			RAISE EXCEPTION 'invalid SRID: % not found in spatial_ref_sys', new_srid;
			RETURN false;
		END IF;
	ELSE
		unknown_srid := public.ST_SRID('POINT EMPTY'::public.geometry);
		IF ( new_srid != unknown_srid ) THEN
			new_srid := unknown_srid;
			RAISE NOTICE 'SRID value % converted to the officially unknown SRID value %', new_srid_in, new_srid;
		END IF;
	END IF;

	IF postgis_constraint_srid(real_schema, table_name, column_name) IS NOT NULL THEN
	-- srid was enforced with constraints before, keep it that way.
		-- Make up constraint name
		cname = 'enforce_srid_'  || column_name;

		-- Drop enforce_srid constraint
		EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
			'.' || quote_ident(table_name) ||
			' DROP constraint ' || quote_ident(cname);

		-- Update geometries SRID
		EXECUTE 'UPDATE ' || quote_ident(real_schema) ||
			'.' || quote_ident(table_name) ||
			' SET ' || quote_ident(column_name) ||
			' = public.ST_SetSRID(' || quote_ident(column_name) ||
			', ' || new_srid::text || ')';

		-- Reset enforce_srid constraint
		EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) ||
			'.' || quote_ident(table_name) ||
			' ADD constraint ' || quote_ident(cname) ||
			' CHECK (st_srid(' || quote_ident(column_name) ||
			') = ' || new_srid::text || ')';
	ELSE
		-- We will use typmod to enforce if no srid constraints
		-- We are using postgis_type_name to lookup the new name
		-- (in case Paul changes his mind and flips geometry_columns to return old upper case name)
		EXECUTE 'ALTER TABLE ' || quote_ident(real_schema) || '.' || quote_ident(table_name) ||
		' ALTER COLUMN ' || quote_ident(column_name) || ' TYPE  geometry(' || public.postgis_type_name(myrec.type, myrec.coord_dimension, true) || ', ' || new_srid::text || ') USING public.ST_SetSRID(' || quote_ident(column_name) || ',' || new_srid::text || ');' ;
	END IF;

	RETURN real_schema || '.' || table_name || '.' || column_name ||' SRID changed to ' || new_srid::text;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.updategeometrysrid(character varying, character varying, character varying, integer)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	ret  text;
BEGIN
	SELECT public.UpdateGeometrySRID('',$1,$2,$3,$4) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.updategeometrysrid(character varying, character varying, integer)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
	ret  text;
BEGIN
	SELECT public.UpdateGeometrySRID('','',$1,$2,$3) into ret;
	RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.uuid_generate_v1()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1$function$
;

CREATE OR REPLACE FUNCTION public.uuid_generate_v1mc()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1mc$function$
;

CREATE OR REPLACE FUNCTION public.uuid_generate_v3(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v3$function$
;

CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v4$function$
;

CREATE OR REPLACE FUNCTION public.uuid_generate_v5(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v5$function$
;

CREATE OR REPLACE FUNCTION public.uuid_nil()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_nil$function$
;

CREATE OR REPLACE FUNCTION public.uuid_ns_dns()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_dns$function$
;

CREATE OR REPLACE FUNCTION public.uuid_ns_oid()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_oid$function$
;

CREATE OR REPLACE FUNCTION public.uuid_ns_url()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_url$function$
;

CREATE OR REPLACE FUNCTION public.uuid_ns_x500()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_x500$function$
;

CREATE OR REPLACE FUNCTION public.wfit_set_default_priority()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.priority IS NULL AND NEW.task_template_id IS NOT NULL THEN
    SELECT t.priority INTO NEW.priority
    FROM workflow_task_templates t
    WHERE t.id = NEW.task_template_id;
  END IF;
  RETURN NEW;
END$function$
;

CREATE OR REPLACE FUNCTION public.word_similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity$function$
;

CREATE OR REPLACE FUNCTION public.word_similarity_commutator_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_commutator_op$function$
;

CREATE OR REPLACE FUNCTION public.word_similarity_dist_commutator_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_dist_commutator_op$function$
;

CREATE OR REPLACE FUNCTION public.word_similarity_dist_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_dist_op$function$
;

CREATE OR REPLACE FUNCTION public.word_similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_op$function$
;

CREATE OR REPLACE FUNCTION topology._asgmledge(edge_id bigint, start_node bigint, end_node bigint, line geometry, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  visited bool;
  nsprefix text;
  gml text;
BEGIN

  nsprefix := 'gml:';
  IF nsprefix_in IS NOT NULL THEN
    IF nsprefix_in = '' THEN
      nsprefix = nsprefix_in;
    ELSE
      nsprefix = nsprefix_in || ':';
    END IF;
  END IF;

  gml := '<' || nsprefix || 'Edge ' || nsprefix
    || 'id="' || idprefix || 'E' || edge_id || '">';

  -- Start node
  gml = gml || '<' || nsprefix || 'directedNode orientation="-"';
  -- Do visited bookkeeping if visitedTable was given
  visited = NULL;
  IF visitedTable IS NOT NULL THEN
    EXECUTE 'SELECT true FROM '
            || visitedTable::text
            || ' WHERE element_type = 1 AND element_id = '
            || start_node LIMIT 1 INTO visited;
    IF visited IS NOT NULL THEN
      gml = gml || ' xlink:href="#' || idprefix || 'N' || start_node || '" />';
    ELSE
      -- Mark as visited
      EXECUTE 'INSERT INTO ' || visitedTable::text
        || '(element_type, element_id) VALUES (1, '
        || start_node || ')';
    END IF;
  END IF;
  IF visited IS NULL THEN
    gml = gml || '>';
    gml = gml || topology._AsGMLNode(start_node, NULL, nsprefix_in,
                                     prec, options, idprefix, gmlver);
    gml = gml || '</' || nsprefix || 'directedNode>';
  END IF;

  -- End node
  gml = gml || '<' || nsprefix || 'directedNode';
  -- Do visited bookkeeping if visitedTable was given
  visited = NULL;
  IF visitedTable IS NOT NULL THEN
    EXECUTE 'SELECT true FROM '
            || visitedTable::text
            || ' WHERE element_type = 1 AND element_id = '
            || end_node LIMIT 1 INTO visited;
    IF visited IS NOT NULL THEN
      gml = gml || ' xlink:href="#' || idprefix || 'N' || end_node || '" />';
    ELSE
      -- Mark as visited
      EXECUTE 'INSERT INTO ' || visitedTable::text
        || '(element_type, element_id) VALUES (1, '
        || end_node || ')';
    END IF;
  END IF;
  IF visited IS NULL THEN
    gml = gml || '>';
    gml = gml || topology._AsGMLNode(end_node, NULL, nsprefix_in,
                                     prec, options, idprefix, gmlver);
    gml = gml || '</' || nsprefix || 'directedNode>';
  END IF;

  IF line IS NOT NULL THEN
    gml = gml || '<' || nsprefix || 'curveProperty>'
              || ST_AsGML(gmlver, line, prec, options, nsprefix_in)
              || '</' || nsprefix || 'curveProperty>';
  END IF;

  gml = gml || '</' || nsprefix || 'Edge>';

  RETURN gml;
END
$function$
;

CREATE OR REPLACE FUNCTION topology._asgmlface(toponame text, face_id bigint, visitedtable regclass, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  visited bool;
  nsprefix text;
  gml text;
  rec RECORD;
  rec2 RECORD;
  bounds geometry;
BEGIN

  nsprefix := 'gml:';
  IF nsprefix_in IS NOT NULL THEN
    IF nsprefix_in = '' THEN
      nsprefix = nsprefix_in;
    ELSE
      nsprefix = nsprefix_in || ':';
    END IF;
  END IF;

  gml := '<' || nsprefix || 'Face ' || nsprefix
    || 'id="' || idprefix || 'F' || face_id || '">';

  -- Construct the face geometry, then for each polygon:
  FOR rec IN SELECT (ST_DumpRings((ST_Dump(ST_ForceRHR(
    topology.ST_GetFaceGeometry(toponame, face_id)))).geom)).geom
  LOOP

      -- Contents of a directed face are the list of edges
      -- that cover the specific ring
      bounds = ST_Boundary(rec.geom);

      FOR rec2 IN EXECUTE
        'SELECT e.*, ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.2)) as pos'
        || ', ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.8)) as pos2 FROM '
        || quote_ident(toponame)
        || '.edge e WHERE ( e.left_face = $2'
        || ' OR e.right_face = $2'
        || ') AND ST_Covers($1'
        || ', e.geom) ORDER BY pos'
        USING bounds, face_id
      LOOP

        gml = gml || '<' || nsprefix || 'directedEdge';

        -- if this edge goes in same direction to the
        --       ring bounds, make it with negative orientation
        IF rec2.pos2 > rec2.pos THEN -- edge goes in same direction
          gml = gml || ' orientation="-"';
        END IF;

        -- Do visited bookkeeping if visitedTable was given
        IF visitedTable IS NOT NULL THEN

          EXECUTE 'SELECT true FROM '
            || visitedTable::text
            || ' WHERE element_type = 2 AND element_id = '
            || rec2.edge_id LIMIT 1 INTO visited;
          IF visited THEN
            -- Use xlink:href if visited
            gml = gml || ' xlink:href="#' || idprefix || 'E'
                      || rec2.edge_id || '" />';
            CONTINUE;
          ELSE
            -- Mark as visited otherwise
            EXECUTE 'INSERT INTO ' || visitedTable::text
              || '(element_type, element_id) VALUES (2, '
              || rec2.edge_id || ')';
          END IF;

        END IF;

        gml = gml || '>';

        gml = gml || topology._AsGMLEdge(rec2.edge_id, rec2.start_node,
                                        rec2.end_node, rec2.geom,
                                        visitedTable, nsprefix_in,
                                        prec, options, idprefix, gmlver);
        gml = gml || '</' || nsprefix || 'directedEdge>';

      END LOOP;
    END LOOP;

  gml = gml || '</' || nsprefix || 'Face>';

  RETURN gml;
END
$function$
;

CREATE OR REPLACE FUNCTION topology._asgmlnode(id bigint, point geometry, nsprefix_in text, prec integer, options integer, idprefix text, gmlver integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
  nsprefix text;
  gml text;
BEGIN

  nsprefix := 'gml:';
  IF NOT nsprefix_in IS NULL THEN
    IF nsprefix_in = '' THEN
      nsprefix = nsprefix_in;
    ELSE
      nsprefix = nsprefix_in || ':';
    END IF;
  END IF;

  gml := '<' || nsprefix || 'Node ' || nsprefix
    || 'id="' || idprefix || 'N' || id || '"';
  IF point IS NOT NULL THEN
    gml = gml || '>'
              || '<' || nsprefix || 'pointProperty>'
              || ST_AsGML(gmlver, point, prec, options, nsprefix_in)
              || '</' || nsprefix || 'pointProperty>'
              || '</' || nsprefix || 'Node>';
  ELSE
    gml = gml || '/>';
  END IF;
  RETURN gml;
END
$function$
;

CREATE OR REPLACE FUNCTION topology._checkedgelinking(curedge_edge_id bigint, prevedge_edge_id bigint, prevedge_next_left_edge bigint, prevedge_next_right_edge bigint)
 RETURNS validatetopology_returntype
 LANGUAGE plpgsql
 IMMUTABLE STRICT
AS $function$
DECLARE
  retrec topology.ValidateTopology_ReturnType;
BEGIN
  IF prevedge_edge_id > 0
  THEN -- previous was outgoing, this one should be next-right
    IF prevedge_next_right_edge != curedge_edge_id THEN
      retrec.error = 'invalid next_right_edge';
      retrec.id1 = abs(prevedge_edge_id);
      retrec.id2 = curedge_edge_id; -- we put the expected one here, for convenience
      RETURN retrec;
    END IF;
  ELSE -- previous was incoming, this one should be next-left
    IF prevedge_next_left_edge != curedge_edge_id THEN
      retrec.error = 'invalid next_left_edge';
      retrec.id1 = abs(prevedge_edge_id);
      retrec.id2 = curedge_edge_id; -- we put the expected one here, for convenience
      RETURN retrec;
    END IF;
  END IF;

  RETURN retrec;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology._registermissingfaces(atopology character varying)
 RETURNS void
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$RegisterMissingFaces$function$
;

CREATE OR REPLACE FUNCTION topology._st_adjacentedges(atopology character varying, anode bigint, anedge bigint)
 RETURNS bigint[]
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  ret bigint[];
BEGIN
  WITH edgestar AS (
    SELECT *, count(*) over () AS cnt
    FROM topology.GetNodeEdges(atopology, anode)
  )
  SELECT ARRAY[ (
      SELECT p.edge AS prev FROM edgestar p
      WHERE p.sequence = CASE WHEN m.sequence-1 < 1 THEN cnt
                         ELSE m.sequence-1 END
    ), (
      SELECT p.edge AS prev FROM edgestar p WHERE p.sequence = ((m.sequence)%cnt)+1
    ) ]
  FROM edgestar m
  WHERE edge = anedge
  INTO ret;

  RETURN ret;
END
$function$
;

CREATE OR REPLACE FUNCTION topology._st_mintolerance(val double precision)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
    SELECT 3.6 * power(10,  - ( 15 - log(val) ));
$function$
;

CREATE OR REPLACE FUNCTION topology._st_mintolerance(ageom geometry)
 RETURNS double precision
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
    SELECT topology._st_mintolerance(coalesce(
      nullif(
        greatest(abs(ST_Xmin($1)), abs(ST_Ymin($1)),
                 abs(ST_Xmax($1)), abs(ST_Ymax($1))),
        0),
      1));
$function$
;

CREATE OR REPLACE FUNCTION topology._st_mintolerance(atopology character varying, ageom geometry)
 RETURNS double precision
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  ret FLOAT8;
BEGIN
  SELECT COALESCE(
    NULLIF(precision, 0),
    topology._st_mintolerance($2))
  FROM topology.topology
  WHERE name = $1 INTO ret;
  IF NOT FOUND THEN
    RAISE EXCEPTION
      'No topology with name "%" in topology.topology', atopology;
  END IF;
  return ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology._topogeo_addlinestringnoface(atopology character varying, aline geometry, tolerance double precision DEFAULT 0)
 RETURNS void
 LANGUAGE c
 STRICT
AS '$libdir/postgis_topology-3', $function$TopoGeo_AddLinestringNoFace$function$
;

CREATE OR REPLACE FUNCTION topology._validatetopologyedgelinking(bbox geometry DEFAULT NULL::geometry)
 RETURNS SETOF validatetopology_returntype
 LANGUAGE plpgsql
AS $function$
DECLARE
  retrec topology.ValidateTopology_ReturnType;
  rec RECORD;
  last_node_id bigint;
  last_node_first_edge RECORD;
  last_node_prev_edge RECORD;
BEGIN
  RAISE NOTICE 'Checking edge linking';
  -- NOTE: this check relies on correct start_node and end_node
  --       for edges, if those are not correct the results
  --       of this check do not make much sense.
  FOR rec IN --{
      WITH
      nodes AS (
        SELECT node_id
        FROM node
        WHERE containing_face IS NULL
        AND (
          bbox IS NULL
          OR geom && bbox
        )
      ),
      incident_edges AS (
        SELECT
          n.node_id,
          e.edge_id,
          e.start_node,
          e.end_node,
          e.next_left_edge,
          e.next_right_edge,
          ST_RemoveRepeatedPoints(e.geom) as edge_geom
        FROM edge_data e, nodes n
        WHERE e.start_node = n.node_id
        or e.end_node = n.node_id
      ),
      edge_star AS (
        SELECT
          node_id,
          edge_id,
          next_left_edge,
          next_right_edge,
          ST_Azimuth(ST_StartPoint(edge_geom), ST_PointN(edge_geom, 2)) as az
        FROM incident_edges
        WHERE start_node = node_id
          UNION ALL
        SELECT
          node_id,
          -edge_id,
          next_left_edge,
          next_right_edge,
          ST_Azimuth(ST_EndPoint(edge_geom), ST_PointN(edge_geom, ST_NumPoints(edge_geom)-1))
        FROM incident_edges
        WHERE end_node = node_id
      ),
      sequenced_edge_star AS (
        SELECT
          row_number() over (partition by node_id order by az, edge_id) seq,
          *
        FROM edge_star
      )
      SELECT * FROM sequenced_edge_star
      ORDER BY node_id, seq
  LOOP --}{
    IF last_node_id IS NULL OR last_node_id != rec.node_id
    THEN --{
      IF last_node_id IS NOT NULL
      THEN
        -- Check that last edge (CW from prev one) is correctly linked
        retrec := topology._CheckEdgeLinking(
          last_node_first_edge.edge_id,
          last_node_prev_edge.edge_id,
          last_node_prev_edge.next_left_edge,
          last_node_prev_edge.next_right_edge
        );
        IF retrec IS NOT NULL
        THEN
          RETURN NEXT retrec;
        END IF;
      END IF;
      last_node_id = rec.node_id;
      last_node_first_edge = rec;
    ELSE --}{
      -- Check that this edge (CW from last one) is correctly linked
      retrec := topology._CheckEdgeLinking(
        rec.edge_id,
        last_node_prev_edge.edge_id,
        last_node_prev_edge.next_left_edge,
        last_node_prev_edge.next_right_edge
      );
      IF retrec IS NOT NULL
      THEN
        RETURN NEXT retrec;
      END IF;
    END IF; --}
    last_node_prev_edge = rec;
  END LOOP; --}
  IF last_node_id IS NOT NULL THEN --{
    -- Check that last edge (CW from prev one) is correctly linked
    retrec := topology._CheckEdgeLinking(
      last_node_first_edge.edge_id,
      last_node_prev_edge.edge_id,
      last_node_prev_edge.next_left_edge,
      last_node_prev_edge.next_right_edge
      );
    IF retrec IS NOT NULL
    THEN
      RETURN NEXT retrec;
    END IF;
  END IF; --}


END;
$function$
;

CREATE OR REPLACE FUNCTION topology._validatetopologygetfaceshellmaximaledgering(atopology character varying, aface bigint)
 RETURNS geometry
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  sql TEXT;
  outsidePoint GEOMETRY;
  leftmostEdge BIGINT;
  shell GEOMETRY;
BEGIN

  sql := format(
    $$
      SELECT
        ST_Translate(
          ST_StartPoint( ST_BoundingDiagonal(mbr) ),
          -1,
          -1
        )
      FROM %1$I.face
      WHERE face_id = $1
    $$,
    atopology
  );
  EXECUTE sql USING aface INTO outsidePoint;

  RAISE NOTICE 'Outside point of face %: %', aface, ST_AsText(outsidePoint);

  IF outsidePoint IS NULL THEN
    RETURN NULL;
  END IF;

  sql := format(
    $$
      SELECT
        CASE WHEN left_face = $1
        THEN
          edge_id
        ELSE
          -edge_id
        END ring_id
      FROM %1$I.edge
      WHERE left_face = $1 or right_face = $1
      ORDER BY
        geom <-> $2
      LIMIT 1
    $$,
    atopology
  );
  EXECUTE sql USING aface, outsidePoint INTO leftmostEdge;

  RAISE NOTICE 'Leftmost edge of face %: %', aface, leftmostEdge;

  IF leftmostEdge IS NULL THEN
    RETURN NULL;
  END IF;

  sql := format(
    $$
      WITH
      edgering AS (
        SELECT *
        FROM
          topology.GetRingEdges(
            %1$L,
            $1
          )
      )
      SELECT
        ST_MakeLine(
          CASE WHEN r.edge > 0 THEN
            e.geom
          ELSE
            ST_Reverse(e.geom)
          END
          ORDER BY r.sequence
        ) outerRing
      FROM edgering r, %1$I.edge e
      WHERE e.edge_id = abs(r.edge)
    $$,
    atopology
  );

  RAISE DEBUG 'SQL: %', sql;

  EXECUTE sql USING leftmostEdge
  INTO shell;

  -- TODO: check if the ring is not closed

  shell := ST_MakePolygon(shell);

  RETURN shell;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology._validatetopologygetringedges(starting_edge bigint)
 RETURNS bigint[]
 LANGUAGE plpgsql
AS $function$
DECLARE
  ret bigint[];
BEGIN
  WITH RECURSIVE edgering AS (
    SELECT
      starting_edge as signed_edge_id,
      edge_id,
      next_left_edge,
      next_right_edge
    FROM edge_data
    WHERE edge_id = abs(starting_edge)
      UNION
    SELECT
      CASE WHEN p.signed_edge_id < 0 THEN
        p.next_right_edge
      ELSE
        p.next_left_edge
      END,
      e.edge_id,
      e.next_left_edge,
      e.next_right_edge
    FROM edge_data e, edgering p
    WHERE e.edge_id =
      CASE WHEN p.signed_edge_id < 0 THEN
        abs(p.next_right_edge)
      ELSE
        abs(p.next_left_edge)
      END
  )
  SELECT array_agg(signed_edge_id)
  FROM edgering
  INTO ret;

  RETURN ret;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology._validatetopologyrings(bbox geometry DEFAULT NULL::geometry)
 RETURNS SETOF validatetopology_returntype
 LANGUAGE plpgsql
AS $function$
DECLARE
  retrec topology.ValidateTopology_ReturnType;
  rec RECORD;
  ring_poly GEOMETRY;
  is_shell BOOLEAN;
  found_rings INT := 0;
  found_shells INT := 0;
  found_holes INT := 0;
BEGIN

  CREATE TEMP TABLE shell_check (
    face_id bigint PRIMARY KEY,
    ring_geom geometry
  );

  CREATE TEMP TABLE hole_check (
    ring_id bigint,
    hole_mbr geometry, -- point
    hole_point geometry, -- point
    in_shell bigint
  );

  RAISE NOTICE 'Building edge rings';

  -- Find all rings that can be formed on both sides
  -- of selected edges
  FOR rec IN
    WITH --{
    considered_edges AS (
      SELECT e.* FROM edge_data e, node n
      WHERE
        ( e.start_node = n.node_id OR e.end_node = n.node_id )
        AND
        ( bbox IS NULL OR n.geom && bbox )
    ),
    forward_rings AS (
      SELECT topology._ValidateTopologyGetRingEdges(e.edge_id) edges
      FROM considered_edges e
    ),
    forward_rings_with_id AS (
      SELECT
        (select min(e) FROM unnest(edges) e) ring_id,
        *
      FROM forward_rings
    ),
    distinct_forward_rings AS (
      SELECT
        DISTINCT ON (ring_id)
        *
      FROM forward_rings_with_id
    ),
    backward_rings AS (
      SELECT topology._ValidateTopologyGetRingEdges(-e.edge_id) edges
      FROM considered_edges e
      WHERE -edge_id NOT IN (
        SELECT x FROM (
          SELECT unnest(edges) x
          FROM distinct_forward_rings
        ) foo
      )
    ),
    backward_rings_with_id AS (
      SELECT
        (select min(e) FROM unnest(edges) e) ring_id,
        *
      FROM backward_rings
    ),
    distinct_backward_rings AS (
      SELECT
        DISTINCT ON (ring_id)
        *
      FROM backward_rings_with_id
    ),
    all_rings AS (
      SELECT * FROM distinct_forward_rings
      UNION
      SELECT * FROM distinct_backward_rings
    ),
    all_rings_with_ring_ordinal_edge AS (
      SELECT
        r.ring_id,
        e.seq,
        e.edge signed_edge_id
      FROM all_rings r
      LEFT JOIN LATERAL unnest(r.edges) WITH ORDINALITY AS e(edge, seq)
      ON TRUE
    ),
    all_rings_with_ring_geom AS (
      SELECT
        r.ring_id,
        ST_MakeLine(
          CASE WHEN signed_edge_id > 0 THEN
            e.geom
          ELSE
            ST_Reverse(e.geom)
          END
           -- TODO: how to make sure rows are ordered ?
          ORDER BY seq
        ) geom,
        array_agg(
          DISTINCT
          CASE WHEN signed_edge_id > 0 THEN
            e.left_face
          ELSE
            e.right_face
          END
        ) side_faces,
        count(signed_edge_id) num_edges,
        count(distinct abs(signed_edge_id)) distinct_edges
      FROM
        all_rings_with_ring_ordinal_edge r,
        edge_data e
      WHERE e.edge_id = abs(r.signed_edge_id)
      GROUP BY ring_id
    ) --}{
    SELECT ring_id, geom as ring_geom, side_faces, distinct_edges, num_edges
    FROM all_rings_with_ring_geom
  LOOP --}{

    found_rings := found_rings + 1;

    -- Check that there's a single face advertised
    IF array_upper(rec.side_faces,1) != 1
    THEN --{

      retrec.error = 'mixed face labeling in ring';
      retrec.id1 = rec.ring_id;
      retrec.id2 = NULL;
      RETURN NEXT retrec;
      CONTINUE;

    END IF; --}

    --RAISE DEBUG 'Ring geom: %', ST_AsTexT(rec.ring_geom);
    --RAISE DEBUG 'Distinct edges: %', rec.distinct_edges;
    --RAISE DEBUG 'Num edges: %', rec.num_edges;

    IF NOT ST_Equals(
      ST_StartPoint(rec.ring_geom),
      ST_EndPoint(rec.ring_geom)
    )
    THEN --{
      -- This should have been reported before,
      -- on the edge linking check
      retrec.error = 'non-closed ring';
      retrec.id1 = rec.ring_id;
      retrec.id2 = NULL;
      RETURN NEXT retrec;
      CONTINUE;
    END IF; --}

    -- Ring is valid, save it.
    is_shell := false;
    IF ST_NPoints(rec.ring_geom) > 3 AND
       rec.num_edges != rec.distinct_edges * 2
    THEN
      ring_poly := ST_MakePolygon(rec.ring_geom);
      IF ST_IsPolygonCCW(ring_poly) THEN
        is_shell := true;
      END IF;
    END IF;


    IF is_shell THEN --{ It's a shell (CCW)
      -- Check that a single face is ever used
      --       for each distinct CCW ring (shell)
      BEGIN
        INSERT INTO shell_check VALUES (
          rec.side_faces[1],
          ring_poly
        );
        found_shells := found_shells + 1;
      EXCEPTION WHEN unique_violation THEN
        retrec.error = 'face has multiple shells';
        retrec.id1 = rec.side_faces[1];
        retrec.id2 = rec.ring_id;
        RETURN NEXT retrec;
      END;
    ELSE -- }{ It's an hole (CW)
    -- NOTE: multiple CW rings (holes) can exist for a given face
      INSERT INTO hole_check VALUES (
        rec.ring_id,
        ST_Envelope(rec.ring_geom),
        ST_PointN(rec.ring_geom, 1),
        -- NOTE: we don't incurr in the risk
        --       of a ring touching the shell
        --       because in those cases the
        --       intruding "hole" will not really
        --       be considered an hole as its ring
        --       will not be CW
        rec.side_faces[1]
      );
      found_holes := found_holes + 1;
    END IF; --} hole

  END LOOP; --}

  RAISE NOTICE 'Found % rings, % valid shells, % valid holes',
    found_rings, found_shells, found_holes
  ;


END;
$function$
;

CREATE OR REPLACE FUNCTION topology.addedge(atopology character varying, aline geometry)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	edgeid bigint;
	rec RECORD;
  ix geometry;
  seq_name_edge_data text;
BEGIN
	--
	-- Atopology and apoint are required
	--
	IF atopology IS NULL OR aline IS NULL THEN
		RAISE EXCEPTION 'Invalid null argument';
	END IF;

	--
	-- Aline must be a linestring
	--
	IF substring(geometrytype(aline), 1, 4) != 'LINE'
	THEN
		RAISE EXCEPTION 'Edge geometry must be a linestring';
	END IF;

	--
	-- Check there's no face registered in the topology
	--
	FOR rec IN EXECUTE 'SELECT count(face_id) FROM '
		|| quote_ident(atopology) || '.face '
		|| ' WHERE face_id != 0 LIMIT 1'
	LOOP
		IF rec.count > 0 THEN
			RAISE EXCEPTION 'AddEdge can only be used against topologies with no faces defined';
		END IF;
	END LOOP;

	--
	-- Check if the edge crosses an existing node
	--
	FOR rec IN EXECUTE 'SELECT node_id FROM '
		|| quote_ident(atopology) || '.node '
		|| 'WHERE ST_Crosses($1, geom)'
    USING aline
	LOOP
		RAISE EXCEPTION 'Edge crosses node %', rec.node_id;
	END LOOP;

	--
	-- Check if the edge intersects an existing edge
	-- on anything but endpoints
	--
	-- Following DE-9 Intersection Matrix represent
	-- the only relation we accept.
	--
	--    F F 1
	--    F * *
	--    1 * 2
	--
	-- Example1: linestrings touching at one endpoint
	--    FF1 F00 102
	--    FF1 F** 1*2 <-- our match
	--
	-- Example2: linestrings touching at both endpoints
	--    FF1 F0F 1F2
	--    FF1 F** 1*2 <-- our match
	--
	FOR rec IN EXECUTE 'SELECT edge_id, geom, ST_Relate($1, geom, 2) as im FROM '
		|| quote_ident(atopology) || '.edge WHERE $1 && geom'
    USING aline
	LOOP

	  IF ST_RelateMatch(rec.im, 'FF1F**1*2') THEN
	    CONTINUE; -- no interior intersection
	  END IF;

	  -- Reuse an EQUAL edge (be it closed or not)
	  IF ST_RelateMatch(rec.im, '1FFF*FFF2') THEN
	      RETURN rec.edge_id;
	  END IF;

    -- WARNING: the constructive operation might throw an exception
    BEGIN
      ix = ST_Intersection(rec.geom, aline);
    EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE
        'Could not compute intersection between'
          ' input edge (%) and edge % (%)',
        aline::text,
        rec.edge_id,
        rec.geom::text;
    END;

    -- Find a point on the intersection which
    -- is NOT an endpoint of "aline"
    IF ST_Dimension(ix) = 0
    THEN
      WITH SharedBounds AS (
        (
          SELECT ST_Force2D(ST_StartPoint(rec.geom)) g
          UNION
          SELECT ST_Force2D(ST_EndPoint(rec.geom))
        )
        INTERSECT
        (
          SELECT ST_Force2D(ST_StartPoint(aline))
          UNION
          SELECT ST_Force2D(ST_EndPoint(aline))
        )
      )
      SELECT d.geom
      FROM ST_DumpPoints(ix) d
      WHERE ST_Force2D(geom) NOT IN ( SELECT g FROM SharedBounds )
      ORDER BY d.path
      LIMIT 1
      INTO STRICT ix;
    ELSE
      -- for linear intersection we pick
      -- an internal point.
      ix := ST_PointOnSurface(ix);
    END IF;

    RAISE EXCEPTION
      'Edge intersects (not on endpoints)'
        ' with existing edge % at or near point %',
      rec.edge_id,
      ST_AsText(ix);

	END LOOP;

	--
	-- Get new edge id from sequence
	--
  EXECUTE FORMAT(
    $fmt$
    SELECT column_default
    FROM information_schema.columns
    WHERE table_schema = %1$L AND table_name='edge_data' AND column_name = 'edge_id'
    $fmt$,
    atopology
  ) INTO seq_name_edge_data;

  FOR rec IN EXECUTE 'SELECT ' || seq_name_edge_data	LOOP
		edgeid = rec.nextval;
	END LOOP;

	--
	-- Insert the new row
	--
	EXECUTE 'INSERT INTO '
		|| quote_ident(atopology)
		|| '.edge(edge_id, start_node, end_node, '
		|| 'next_left_edge, next_right_edge, '
		|| 'left_face, right_face, '
		|| 'geom) '
		|| ' VALUES('

		-- edge_id
		|| edgeid ||','

		-- start_node
		|| 'topology.addNode('
		|| quote_literal(atopology)
		|| ', ST_StartPoint($1)), '

		-- end_node
		|| 'topology.addNode('
		|| quote_literal(atopology)
		|| ', ST_EndPoint($1)), '

		-- next_left_edge
		|| -edgeid ||','

		-- next_right_edge
		|| edgeid ||','

		-- left_face
		|| '0,'

		-- right_face
		|| '0,'

		-- geom
		|| '$1)'
    USING aline;

	RETURN edgeid;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.addface(atopology character varying, apoly geometry, force_new boolean DEFAULT false)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  bounds geometry;
  symdif geometry;
  faceid int8;
  rec RECORD;
  rrec RECORD;
  relate text;
  right_edges int8[];
  left_edges int8[];
  all_edges geometry;
  old_faceid int8;
  old_edgeid int8;
  sql text;
  right_side bool;
  edgeseg geometry;
  p1 geometry;
  p2 geometry;
  p3 geometry;
  loc float8;
  segnum int;
  numsegs int;
  seq_name_face text;
BEGIN
  --
  -- Atopology and apoly are required
  --
  IF atopology IS NULL OR apoly IS NULL THEN
    RAISE EXCEPTION 'Invalid null argument';
  END IF;

  --
  -- Aline must be a polygon
  --
  IF substring(geometrytype(apoly), 1, 4) != 'POLY'
  THEN
    RAISE EXCEPTION 'Face geometry must be a polygon';
  END IF;

  for rrec IN SELECT (d).* FROM (
    SELECT ST_DumpRings(ST_ForceRHR(apoly)) d
  ) foo
  LOOP -- {
    --
    -- Find all bounds edges, forcing right-hand-rule
    -- to know what's left and what's right...
    --
    bounds = ST_Boundary(rrec.geom);

    sql := 'SELECT e.geom, e.edge_id, e.left_face, e.right_face FROM '
      || quote_ident(atopology)
      || '.edge e, (SELECT $1 as geom) r WHERE r.geom && e.geom'
    ;
    -- RAISE DEBUG 'SQL: %', sql;
    FOR rec IN EXECUTE sql USING bounds
    LOOP -- {
      --RAISE DEBUG 'Edge % has bounding box intersection', rec.edge_id;

      -- Find first non-empty segment of the edge
      numsegs = ST_NumPoints(rec.geom);
      segnum = 1;
      WHILE segnum < numsegs LOOP
        p1 = ST_PointN(rec.geom, segnum);
        p2 = ST_PointN(rec.geom, segnum+1);
        IF ST_Distance(p1, p2) > 0 THEN
          EXIT;
        END IF;
        segnum = segnum + 1;
      END LOOP;

      IF segnum = numsegs THEN
        RAISE WARNING 'Edge % is collapsed', rec.edge_id;
        CONTINUE; -- we don't want to spend time on it
      END IF;

      edgeseg = ST_MakeLine(p1, p2);

      -- Skip non-covered edges
      IF NOT ST_Equals(p2, ST_EndPoint(rec.geom)) THEN
        IF NOT ( _ST_Intersects(bounds, p1) AND _ST_Intersects(bounds, p2) )
        THEN
          --RAISE DEBUG 'Edge % has points % and % not intersecting with ring bounds', rec.edge_id, st_astext(p1), st_astext(p2);
          CONTINUE;
        END IF;
      ELSE
        -- must be a 2-points only edge, let's use Covers (more expensive)
        IF NOT _ST_Covers(bounds, edgeseg) THEN
          --RAISE DEBUG 'Edge % is not covered by ring', rec.edge_id;
          CONTINUE;
        END IF;
      END IF;

      p3 = ST_StartPoint(bounds);
      IF ST_DWithin(edgeseg, p3, 0) THEN
        -- Edge segment covers ring endpoint, See bug #874
        loc = ST_LineLocatePoint(edgeseg, p3);
        -- WARNING: this is as robust as length of edgeseg allows...
        IF loc > 0.9 THEN
          -- shift last point down
          p2 = ST_LineInterpolatePoint(edgeseg, loc - 0.1);
        ELSIF loc < 0.1 THEN
          -- shift first point up
          p1 = ST_LineInterpolatePoint(edgeseg, loc + 0.1);
        ELSE
          -- when ring start point is in between, we swap the points
          p3 = p1; p1 = p2; p2 = p3;
        END IF;
      END IF;

      right_side = ST_LineLocatePoint(bounds, p1) <
                   ST_LineLocatePoint(bounds, p2);


      IF right_side THEN
        right_edges := array_append(right_edges, rec.edge_id::int8);
        old_faceid = rec.right_face;
      ELSE
        left_edges := array_append(left_edges, rec.edge_id::int8);
        old_faceid = rec.left_face;
      END IF;

      IF faceid IS NULL OR faceid = 0 THEN
        faceid = old_faceid;
        old_edgeid = rec.edge_id;
      ELSIF faceid != old_faceid THEN
        RAISE EXCEPTION 'Edge % has face % registered on the side of this face, while edge % has face % on the same side', rec.edge_id, old_faceid, old_edgeid, faceid;
      END IF;

      -- Collect all edges for final full coverage check
      all_edges = ST_Collect(all_edges, rec.geom);

    END LOOP; -- }
  END LOOP; -- }

  IF all_edges IS NULL THEN
    RAISE EXCEPTION 'Found no edges on the polygon boundary';
  END IF;


  --
  -- Check that all edges found, taken together,
  -- fully match the ring boundary and nothing more
  --
  -- If the test fail either we need to add more edges
  -- from the polygon ring or we need to split
  -- some of the existing ones.
  --
  bounds = ST_Boundary(apoly);
  IF NOT ST_isEmpty(ST_SymDifference(bounds, all_edges)) THEN
    IF NOT ST_isEmpty(ST_Difference(bounds, all_edges)) THEN
      RAISE EXCEPTION 'Polygon boundary is not fully defined by existing edges at or near point %', ST_AsText(ST_PointOnSurface(ST_Difference(bounds, all_edges)));
    ELSE
      RAISE EXCEPTION 'Existing edges cover polygon boundary and more at or near point % (invalid topology?)', ST_AsText(ST_PointOnSurface(ST_Difference(all_edges, bounds)));
    END IF;
  END IF;

  IF faceid IS NOT NULL AND faceid != 0 THEN
    IF NOT force_new THEN
      RETURN faceid;
    ELSE
    END IF;
  END IF;

  --
  -- Get new face id from sequence
  --
  EXECUTE FORMAT(
    $fmt$
    SELECT column_default
    FROM information_schema.columns
    WHERE table_schema = %1$L AND table_name='face' AND column_name = 'face_id'
    $fmt$,
    atopology
  ) INTO seq_name_face;

  FOR rec IN EXECUTE 'SELECT ' || seq_name_face
  LOOP
    faceid = rec.nextval;
  END LOOP;

  --
  -- Insert new face
  --
  EXECUTE 'INSERT INTO '
    || quote_ident(atopology)
    || '.face(face_id, mbr) VALUES('
    -- face_id
    || faceid || ','
    -- minimum bounding rectangle
    || '$1)'
    USING ST_Envelope(apoly);

  --
  -- Update all edges having this face on the left
  --
  IF left_edges IS NOT NULL THEN
    EXECUTE 'UPDATE '
    || quote_ident(atopology)
    || '.edge_data SET left_face = '
    || quote_literal(faceid)
    || ' WHERE edge_id = ANY('
    || quote_literal(left_edges)
    || ') ';
  END IF;

  --
  -- Update all edges having this face on the right
  --
  IF right_edges IS NOT NULL THEN
    EXECUTE 'UPDATE '
    || quote_ident(atopology)
    || '.edge_data SET right_face = '
    || quote_literal(faceid)
    || ' WHERE edge_id = ANY('
    || quote_literal(right_edges)
    || ') ';
  END IF;

  --
  -- Set left_face/right_face of any contained edge
  --
  EXECUTE 'UPDATE '
    || quote_ident(atopology)
    || '.edge_data SET right_face = '
    || quote_literal(faceid)
    || ', left_face = '
    || quote_literal(faceid)
    || ' WHERE ST_Contains($1, geom)'
    USING apoly;

  --
  -- Set containing_face of any contained node
  --
  EXECUTE 'UPDATE '
    || quote_ident(atopology)
    || '.node SET containing_face = '
    || quote_literal(faceid)
    || ' WHERE containing_face IS NOT NULL AND ST_Contains($1, geom)'
    USING apoly;

  RETURN faceid;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.addnode(atopology character varying, apoint geometry, allowedgesplitting boolean DEFAULT false, setcontainingface boolean DEFAULT false)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	nodeid bigint;
	rec RECORD;
  containing_face bigint;
  seq_name_node text;
BEGIN
	--
	-- Atopology and apoint are required
	--
	IF atopology IS NULL OR apoint IS NULL THEN
		RAISE EXCEPTION 'Invalid null argument';
	END IF;

	--
	-- Apoint must be a point
	--
	IF substring(geometrytype(apoint), 1, 5) != 'POINT'
	THEN
		RAISE EXCEPTION 'Node geometry must be a point';
	END IF;

	--
	-- Check if a coincident node already exists
	--
	-- We use index AND x/y equality
	--
	FOR rec IN EXECUTE 'SELECT node_id FROM '
		|| quote_ident(atopology) || '.node ' ||
		'WHERE geom && $1 AND ST_X(geom) = ST_X($1) AND ST_Y(geom) = ST_Y($1)'
    USING apoint
	LOOP
		RETURN  rec.node_id;
	END LOOP;

	--
	-- Check if any edge crosses this node
	-- (endpoints are fine)
	--
	FOR rec IN EXECUTE 'SELECT edge_id FROM '
		|| quote_ident(atopology) || '.edge '
		|| 'WHERE ST_DWithin($1, geom, 0) AND '
    || 'NOT ST_Equals($1, ST_StartPoint(geom)) AND '
    || 'NOT ST_Equals($1, ST_EndPoint(geom))'
    USING apoint
	LOOP
    IF allowEdgeSplitting THEN
      RETURN topology.ST_ModEdgeSplit(atopology, rec.edge_id, apoint);
    ELSE
		  RAISE EXCEPTION 'An edge crosses the given node.';
    END IF;
	END LOOP;

  IF setContainingFace THEN
    containing_face := topology.GetFaceByPoint(atopology, apoint, 0);
  ELSE
    containing_face := NULL;
  END IF;

	--
	-- Get new node id from sequence
	--
  EXECUTE FORMAT(
    $fmt$
    SELECT column_default
    FROM information_schema.columns
    WHERE table_schema = %1$L AND table_name='node' AND column_name = 'node_id'
    $fmt$,
    atopology
  ) INTO seq_name_node;

	FOR rec IN EXECUTE 'SELECT ' || seq_name_node
	LOOP
		nodeid = rec.nextval;
	END LOOP;

	--
	-- Insert the new row
	--
	EXECUTE 'INSERT INTO ' || quote_ident(atopology)
		|| '.node(node_id, containing_face, geom)
		VALUES(' || nodeid || ',' || coalesce(containing_face::text, 'NULL')
    || ',$1)' USING apoint;

	RETURN nodeid;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.addtopogeometrycolumn(toponame name, tab regclass, col name, layerid integer, layertype character varying, child integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
  intlayertype integer;
  newlevel integer;
  topoid integer;
  rec RECORD;
  newlayer_id integer;
  query text;
  cnt integer;
  schema varchar;
  tbl varchar;
  sql TEXT;
BEGIN
  IF layerid IS NOT NULL and layerid <= 0 THEN
    RAISE EXCEPTION 'Invalid Layer ID % (must be > 0)', layerid;
  END IF;

  SELECT n.nspname::text, c.relname::text INTO schema, tbl
  FROM pg_class c
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE c.oid = tab;

  --RAISE NOTICE 'Creating % %.%', tab, schema, tbl;

  -- Get topology id
  SELECT id INTO topoid
    FROM topology.topology WHERE name = toponame;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topology % does not exist', quote_literal(toponame);
  END IF;

  IF layertype ILIKE '%POINT%' OR layertype ILIKE 'PUNTAL' THEN
    intlayertype = 1;
  ELSIF layertype ILIKE '%LINE%' OR layertype ILIKE 'LINEAL' THEN
    intlayertype = 2;
  ELSIF layertype ILIKE '%POLYGON%' OR layertype ILIKE 'AREAL' THEN
    intlayertype = 3;
  ELSIF layertype ILIKE '%COLLECTION%' OR layertype ILIKE 'GEOMETRY' THEN
    intlayertype = 4;
  ELSE
    RAISE EXCEPTION 'Layer type must be one of POINT,LINE,POLYGON,COLLECTION';
  END IF;

  --
  -- Add new TopoGeometry column in tab
  --
  EXECUTE 'ALTER TABLE ' || tab::text
    || ' ADD COLUMN ' || quote_ident(col)
    || ' topology.TopoGeometry;';

  --
  -- See if child id exists and extract its level
  --
  IF child IS NOT NULL THEN
    SELECT level + 1 FROM topology.layer
      WHERE layer_id = child
        AND topology_id = topoid
      INTO newlevel;
    IF newlevel IS NULL THEN
      RAISE EXCEPTION 'Child layer % does not exist in topology "%"', child, toponame;
    END IF;
  END IF;

  -- Get new layer id from sequence
  --
  EXECUTE 'SELECT nextval(' ||
    quote_literal(
      quote_ident(toponame) || '.layer_id_seq'
    ) || ')' INTO STRICT newlayer_id;

  IF layerid IS NOT NULL THEN
    -- Check if the id is already used
    SELECT count(*)
    INTO cnt
    FROM topology.layer
    WHERE layer_id = layerid;

    IF cnt > 0 THEN
      RAISE EXCEPTION 'Layer ID % is already in use', layerid;
    END IF;

    IF layerid > newlayer_id THEN
      -- set sequence to match layer id
      EXECUTE 'SELECT setval(' ||
        quote_literal(
          quote_ident(toponame) || '.layer_id_seq') || ', ' || layerid ||
        ')' INTO STRICT newlayer_id;
    END IF;

    newlayer_id := layerid;
  END IF;

  sql := 'INSERT INTO '
       'topology.layer(topology_id, '
       'layer_id, level, child_id, schema_name, '
       'table_name, feature_column, feature_type) '
       'VALUES ('
    || topoid || ','
    || newlayer_id || ',' || COALESCE(newlevel, 0) || ','
    || COALESCE(child::text, 'NULL') || ','
    || quote_literal(schema) || ','
    || quote_literal(tbl) || ','
    || quote_literal(col) || ','
    || intlayertype || ');';

  EXECUTE sql;

  --
  -- Create a sequence for TopoGeometries in this new layer
  --
  EXECUTE 'CREATE SEQUENCE ' || quote_ident(toponame)
    || '.topogeo_s_' || newlayer_id;

  --
  -- Add constraints on TopoGeom column
  --
  EXECUTE 'ALTER TABLE ' || tab::text
    || ' ADD CONSTRAINT "check_topogeom_' || col || '" CHECK ('
       'topology_id(' || quote_ident(col) || ') = ' || topoid
    || ' AND '
       'layer_id(' || quote_ident(col) || ') = ' || newlayer_id
    || ' AND '
       'type(' || quote_ident(col) || ') = ' || intlayertype
    || ');';

  --
  -- Add dependency of the feature column on the topology schema
  --
  query = 'INSERT INTO pg_catalog.pg_depend SELECT '
       'fcat.oid, fobj.oid, fsub.attnum, tcat.oid, '
       'tobj.oid, 0, ''n'' '
       'FROM pg_class fcat, pg_namespace fnsp, '
       ' pg_class fobj, pg_attribute fsub, '
       ' pg_class tcat, pg_namespace tobj '
       ' WHERE fcat.relname = ''pg_class'' '
       ' AND fnsp.nspname = ' || quote_literal(schema)
    || ' AND fobj.relnamespace = fnsp.oid '
       ' AND fobj.relname = ' || quote_literal(tbl)
    || ' AND fsub.attrelid = fobj.oid '
       ' AND fsub.attname = ' || quote_literal(col)
    || ' AND tcat.relname = ''pg_namespace'' '
       ' AND tobj.nspname = ' || quote_literal(toponame);

--
-- The only reason to add this dependency is to avoid
-- simple drop of a feature column. Still, drop cascade
-- will remove both the feature column and the sequence
-- corrupting the topology anyway ...
--

  RETURN newlayer_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.addtopogeometrycolumn(toponame name, schema name, tbl name, col name, ltype character varying, child integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE sql
AS $function$
  SELECT topology.AddTopoGeometryColumn($1, format('%I.%I', $2, $3)::regclass, $4, null, $5, $6);
$function$
;

CREATE OR REPLACE FUNCTION topology.addtosearchpath(a_schema_name character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
	var_result text;
	var_cur_search_path text;
	a_schema_name text := $1;
BEGIN
	WITH settings AS (
		SELECT unnest(setconfig) config
		FROM pg_db_role_setting
		WHERE setdatabase = (
			SELECT oid
			FROM pg_database
			WHERE datname = current_database()
		) and setrole = 0
	)
	SELECT regexp_replace(config, '^search_path=', '')
	FROM settings WHERE config like 'search_path=%'
	INTO var_cur_search_path;

	RAISE NOTICE 'cur_search_path from pg_db_role_setting is %', var_cur_search_path;

	-- only run this test if person creating the extension is a super user
	IF var_cur_search_path IS NULL AND (SELECT rolsuper FROM pg_roles where rolname = CURRENT_USER) THEN
		SELECT setting
		INTO var_cur_search_path
		FROM pg_file_settings
		WHERE name = 'search_path' AND applied;

		RAISE NOTICE 'cur_search_path from pg_file_settings is %', var_cur_search_path;
	END IF;

	IF var_cur_search_path IS NULL THEN
		SELECT boot_val
		INTO var_cur_search_path
		FROM pg_settings
		WHERE name = 'search_path';

		RAISE NOTICE 'cur_search_path from pg_settings is %', var_cur_search_path;
	END IF;

	IF var_cur_search_path LIKE '%' || quote_ident(a_schema_name) || '%' THEN
		var_result := a_schema_name || ' already in database search_path';
	ELSE
		var_cur_search_path := var_cur_search_path || ', '
                       || quote_ident(a_schema_name);
		EXECUTE 'ALTER DATABASE ' || quote_ident(current_database())
                             || ' SET search_path = ' || var_cur_search_path;
		var_result := a_schema_name || ' has been added to end of database search_path ';
	END IF;

	EXECUTE 'SET search_path = ' || var_cur_search_path;

  RETURN var_result;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, nsprefix_in text, precision_in integer, options_in integer, visitedtable regclass, idprefix text, gmlver integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  nsprefix text;
  precision int;
  options int;
  visited bool;
  toponame text;
  gml text;
  sql text;
  rec RECORD;
  rec2 RECORD;
BEGIN

  nsprefix := 'gml:';
  IF nsprefix_in IS NOT NULL THEN
    IF nsprefix_in = '' THEN
      nsprefix = nsprefix_in;
    ELSE
      nsprefix = nsprefix_in || ':';
    END IF;
  END IF;

  precision := 15;
  IF precision_in IS NOT NULL THEN
    precision = precision_in;
  END IF;

  options := 1;
  IF options_in IS NOT NULL THEN
    options = options_in;
  END IF;

  -- Get topology name (for subsequent queries)
  SELECT name FROM topology.topology into toponame
              WHERE id = tg.topology_id;

  -- Puntual TopoGeometry
  IF tg.type = 1 THEN
    gml = '<' || nsprefix || 'TopoPoint>';
    -- For each defining node, print a directedNode
    FOR rec IN  EXECUTE 'SELECT r.element_id, n.geom from '
      || quote_ident(toponame) || '.relation r LEFT JOIN '
      || quote_ident(toponame) || '.node n ON (r.element_id = n.node_id)'
      || ' WHERE r.layer_id = ' || tg.layer_id
      || ' AND r.topogeo_id = ' || tg.id
    LOOP
      gml = gml || '<' || nsprefix || 'directedNode';
      -- Do visited bookkeeping if visitedTable was given
      IF visitedTable IS NOT NULL THEN
        EXECUTE 'SELECT true FROM '
                || visitedTable::text
                || ' WHERE element_type = 1 AND element_id = '
                || rec.element_id LIMIT 1 INTO visited;
        IF visited IS NOT NULL THEN
          gml = gml || ' xlink:href="#' || idprefix || 'N' || rec.element_id || '" />';
          CONTINUE;
        ELSE
          -- Mark as visited
          EXECUTE 'INSERT INTO ' || visitedTable::text
            || '(element_type, element_id) VALUES (1, '
            || rec.element_id || ')';
        END IF;
      END IF;
      gml = gml || '>';
      gml = gml || topology._AsGMLNode(rec.element_id, rec.geom, nsprefix_in, precision, options, idprefix, gmlver);
      gml = gml || '</' || nsprefix || 'directedNode>';
    END LOOP;
    gml = gml || '</' || nsprefix || 'TopoPoint>';
    RETURN gml;

  ELSIF tg.type = 2 THEN -- lineal
    gml = '<' || nsprefix || 'TopoCurve>';

    FOR rec IN SELECT (ST_Dump(topology.Geometry(tg))).geom
    LOOP
      FOR rec2 IN EXECUTE
        'SELECT e.*, ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.2)) as pos'
        || ', ST_LineLocatePoint($1'
        || ', ST_LineInterpolatePoint(e.geom, 0.8)) as pos2 FROM '
        || quote_ident(toponame)
        || '.edge e WHERE ST_Covers($1'
        || ', e.geom) ORDER BY pos'
        -- TODO: add relation to the conditional, to reduce load ?
        USING rec.geom
      LOOP

        gml = gml || '<' || nsprefix || 'directedEdge';

        -- if this edge goes in opposite direction to the
        --       line, make it with negative orientation
        IF rec2.pos2 < rec2.pos THEN -- edge goes in opposite direction
          gml = gml || ' orientation="-"';
        END IF;

        -- Do visited bookkeeping if visitedTable was given
        IF visitedTable IS NOT NULL THEN

          EXECUTE 'SELECT true FROM '
            || visitedTable::text
            || ' WHERE element_type = 2 AND element_id = '
            || rec2.edge_id LIMIT 1 INTO visited;
          IF visited THEN
            -- Use xlink:href if visited
            gml = gml || ' xlink:href="#' || idprefix || 'E' || rec2.edge_id || '" />';
            CONTINUE;
          ELSE
            -- Mark as visited otherwise
            EXECUTE 'INSERT INTO ' || visitedTable::text
              || '(element_type, element_id) VALUES (2, '
              || rec2.edge_id || ')';
          END IF;

        END IF;

        gml = gml || '>';

        gml = gml || topology._AsGMLEdge(rec2.edge_id,
                                        rec2.start_node,
                                        rec2.end_node, rec2.geom,
                                        visitedTable,
                                        nsprefix_in, precision,
                                        options, idprefix, gmlver);

        gml = gml || '</' || nsprefix || 'directedEdge>';
      END LOOP;
    END LOOP;

    gml = gml || '</' || nsprefix || 'TopoCurve>';
    return gml;

  ELSIF tg.type = 3 THEN -- areal
    gml = '<' || nsprefix || 'TopoSurface>';

    -- For each defining face, print a directedFace
    FOR rec IN  EXECUTE 'SELECT f.face_id from '
      || quote_ident(toponame) || '.relation r LEFT JOIN '
      || quote_ident(toponame) || '.face f ON (r.element_id = f.face_id)'
      || ' WHERE r.layer_id = ' || tg.layer_id
      || ' AND r.topogeo_id = ' || tg.id
    LOOP
      gml = gml || '<' || nsprefix || 'directedFace';
      -- Do visited bookkeeping if visitedTable was given
      IF visitedTable IS NOT NULL THEN
        EXECUTE 'SELECT true FROM '
                || visitedTable::text
                || ' WHERE element_type = 3 AND element_id = '
                || rec.face_id LIMIT 1 INTO visited;
        IF visited IS NOT NULL THEN
          gml = gml || ' xlink:href="#' || idprefix || 'F' || rec.face_id || '" />';
          CONTINUE;
        ELSE
          -- Mark as visited
          EXECUTE 'INSERT INTO ' || visitedTable::text
            || '(element_type, element_id) VALUES (3, '
            || rec.face_id || ')';
        END IF;
      END IF;
      gml = gml || '>';
      gml = gml || topology._AsGMLFace(toponame, rec.face_id, visitedTable,
                                       nsprefix_in, precision,
                                       options, idprefix, gmlver);
      gml = gml || '</' || nsprefix || 'directedFace>';
    END LOOP;
    gml = gml || '</' || nsprefix || 'TopoSurface>';
    RETURN gml;

  ELSIF tg.type = 4 THEN -- collection
    RAISE EXCEPTION 'Collection TopoGeometries are not supported by AsGML';

  END IF;

  RETURN gml;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, options integer, visitedtable regclass, idprefix text)
 RETURNS text
 LANGUAGE sql
AS $function$
 SELECT topology.AsGML($1, $2, $3, $4, $5, $6, 3);
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, options integer, vis regclass)
 RETURNS text
 LANGUAGE sql
AS $function$
 SELECT topology.AsGML($1, $2, $3, $4, $5, '');
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, nsprefix text, prec integer, opts integer)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
 SELECT topology.AsGML($1, $2, $3, $4, NULL);
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, nsprefix text)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
 SELECT topology.AsGML($1, $2, 15, 1, NULL);
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, visitedtable regclass)
 RETURNS text
 LANGUAGE sql
AS $function$
 SELECT topology.AsGML($1, 'gml', 15, 1, $2);
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry, visitedtable regclass, nsprefix text)
 RETURNS text
 LANGUAGE sql
AS $function$
 SELECT topology.AsGML($1, $3, 15, 1, $2);
$function$
;

CREATE OR REPLACE FUNCTION topology.asgml(tg topogeometry)
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
 SELECT topology.AsGML($1, 'gml');
$function$
;

CREATE OR REPLACE FUNCTION topology.astopojson(tg topogeometry, edgemaptable regclass)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  toponame text;
  json text;
  sql text;
  rec RECORD;
  rec2 RECORD;
  side int8;
  arcid int8;
  arcs int8[];
  ringtxt TEXT[];
  comptxt TEXT[];
  edges_found BOOLEAN;
  old_search_path TEXT;
  all_faces int8[];
  faces int8[];
  shell_faces int8[];
  visited_edges int8[];
  looking_for_holes BOOLEAN;
BEGIN

  IF tg IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get topology name (for subsequent queries)
  SELECT name FROM topology.topology into toponame
              WHERE id = tg.topology_id;

  -- TODO: implement scale ?

  -- Puntal TopoGeometry, simply delegate to AsGeoJSON
  IF tg.type = 1 THEN
    json := ST_AsGeoJSON(topology.Geometry(tg));
    return json;
  ELSIF tg.type = 2 THEN -- lineal

    FOR rec IN SELECT (ST_Dump(topology.Geometry(tg))).geom
    LOOP -- {

      sql := 'SELECT e.*, ST_LineLocatePoint($1'
            || ', ST_LineInterpolatePoint(e.geom, 0.2)) as pos'
            || ', ST_LineLocatePoint($1'
            || ', ST_LineInterpolatePoint(e.geom, 0.8)) as pos2 FROM '
            || quote_ident(toponame)
            || '.edge e WHERE ST_Covers($1'
            || ', e.geom) ORDER BY pos';
            -- TODO: add relation to the conditional, to reduce load ?
      FOR rec2 IN EXECUTE sql USING rec.geom
      LOOP -- {

        IF edgeMapTable IS NOT NULL THEN
          sql := 'SELECT arc_id-1 FROM ' || edgeMapTable::text || ' WHERE edge_id = $1';
          EXECUTE sql INTO arcid USING rec2.edge_id;
          IF arcid IS NULL THEN
            EXECUTE 'INSERT INTO ' || edgeMapTable::text
              || '(edge_id) VALUES ($1) RETURNING arc_id-1'
            INTO arcid USING rec2.edge_id;
          END IF;
        ELSE
          arcid := rec2.edge_id;
        END IF;

        -- edge goes in opposite direction
        IF rec2.pos2 < rec2.pos THEN
          arcid := -(arcid+1);
        END IF;

        arcs := arcs || arcid::int8;

      END LOOP; -- }

      comptxt := comptxt || ( '[' || array_to_string(arcs, ',') || ']' );
      arcs := NULL;

    END LOOP; -- }

    json := '{ "type": "MultiLineString", "arcs": [' || array_to_string(comptxt,',') || ']}';

    return json;

  ELSIF tg.type = 3 THEN -- areal

    json := '{ "type": "MultiPolygon", "arcs": [';

    EXECUTE 'SHOW search_path' INTO old_search_path;
    EXECUTE 'SET search_path TO ' || quote_ident(toponame) || ',' || old_search_path;

    SELECT array_agg(id) as f
    FROM ( SELECT (topology.GetTopoGeomElements(tg))[1] as id ) as f
    INTO all_faces;


    visited_edges := ARRAY[]::int8[];
    faces := all_faces;
    looking_for_holes := false;
    shell_faces := ARRAY[]::int8[];

    CREATE TEMP TABLE _postgis_topology_astopojson_tmp_edges
    ON COMMIT DROP
    AS
    SELECT
         ROW_NUMBER() OVER (
            ORDER BY
              ST_XMin(e.geom),
              ST_YMin(e.geom),
              edge_id
         ) leftmost_index,
         e.edge_id,
         e.left_face,
         e.right_face,
         e.next_right_edge,
         e.next_left_edge
    FROM edge e
    WHERE
         ( e.left_face = ANY ( all_faces ) OR
           e.right_face = ANY ( all_faces ) )
    ;
    CREATE INDEX on _postgis_topology_astopojson_tmp_edges (edge_id);

    LOOP -- { until all edges were visited

      arcs := NULL;
      edges_found := false;


      FOR rec in -- {
WITH RECURSIVE
_edges AS (
  SELECT
     *,
     left_face = ANY ( faces ) as lf,
     right_face = ANY ( faces ) as rf
  FROM
    _postgis_topology_astopojson_tmp_edges
),
_leftmost_non_dangling_edge AS (
  SELECT e.edge_id
    FROM _edges e WHERE e.lf != e.rf
  ORDER BY
    leftmost_index
  LIMIT 1
),
_edgepath AS (
  SELECT
    CASE
      WHEN e.lf THEN lme.edge_id
      ELSE -lme.edge_id
    END as signed_edge_id,
    false as back,

    e.lf = e.rf as dangling,
    e.left_face, e.right_face,
    e.lf, e.rf,
    e.next_right_edge, e.next_left_edge

  FROM _edges e, _leftmost_non_dangling_edge lme
  WHERE e.edge_id = abs(lme.edge_id)
    UNION
  SELECT
    CASE
      WHEN p.dangling AND NOT p.back THEN -p.signed_edge_id
      WHEN p.signed_edge_id < 0 THEN p.next_right_edge
      ELSE p.next_left_edge
    END, -- signed_edge_id
    CASE
      WHEN p.dangling AND NOT p.back THEN true
      ELSE false
    END, -- back

    e.lf = e.rf, -- dangling
    e.left_face, e.right_face,
    e.lf, e.rf,
    e.next_right_edge, e.next_left_edge

  FROM _edges e, _edgepath p
  WHERE
    e.edge_id = CASE
      WHEN p.dangling AND NOT p.back THEN abs(p.signed_edge_id)
      WHEN p.signed_edge_id < 0 THEN abs(p.next_right_edge)
      ELSE abs(p.next_left_edge)
    END
)
SELECT abs(signed_edge_id) as edge_id, signed_edge_id, dangling,
        lf, rf, left_face, right_face
FROM _edgepath
      -- }

      LOOP  -- { over recursive query


        IF rec.left_face = ANY (all_faces) AND NOT rec.left_face = ANY (shell_faces) THEN
          shell_faces := shell_faces || rec.left_face::int8;
        END IF;

        IF rec.right_face = ANY (all_faces) AND NOT rec.right_face = ANY (shell_faces) THEN
          shell_faces := shell_faces || rec.right_face::int8;
        END IF;

        visited_edges := visited_edges || rec.edge_id::int8;

        edges_found := true;

        -- TODO: drop ?
        IF rec.dangling THEN
          CONTINUE;
        END IF;

        IF rec.left_face = ANY (all_faces) AND rec.right_face = ANY (all_faces) THEN
          CONTINUE;
        END IF;

        IF edgeMapTable IS NOT NULL THEN
          sql := 'SELECT arc_id-1 FROM ' || edgeMapTable::text || ' WHERE edge_id = $1';
          EXECUTE sql INTO arcid USING rec.edge_id;
          IF arcid IS NULL THEN
            EXECUTE 'INSERT INTO ' || edgeMapTable::text
              || '(edge_id) VALUES ($1) RETURNING arc_id-1'
            INTO arcid USING rec.edge_id;
          END IF;
        ELSE
          arcid := rec.edge_id-1;
        END IF;

        -- Swap sign, use two's complement for negative edges
        IF rec.signed_edge_id >= 0 THEN
          arcid := - ( arcid + 1 );
        END IF;


        arcs := arcid::int8 || arcs;

      END LOOP; -- } over recursive query

      DELETE from _postgis_topology_astopojson_tmp_edges
      WHERE edge_id = ANY (visited_edges);
      visited_edges := ARRAY[]::int8[];


      IF NOT edges_found THEN -- {

        IF looking_for_holes THEN
          looking_for_holes := false;
          comptxt := comptxt || ( '[' || array_to_string(ringtxt, ',') || ']' );
          ringtxt := NULL;
          faces := all_faces;
          shell_faces := ARRAY[]::int8[];
        ELSE
          EXIT; -- end of loop
        END IF;

      ELSE -- } edges found {

        faces := shell_faces;
        IF arcs IS NOT NULL THEN
          ringtxt := ringtxt || ( '[' || array_to_string(arcs,',') || ']' );
        END IF;
        looking_for_holes := true;

      END IF; -- }

    END LOOP; -- }

    DROP TABLE _postgis_topology_astopojson_tmp_edges;

    json := json || array_to_string(comptxt, ',') || ']}';

    EXECUTE 'SET search_path TO ' || old_search_path;

  ELSIF tg.type = 4 THEN -- collection
    RAISE EXCEPTION 'Collection TopoGeometries are not supported by AsTopoJSON';

  END IF;

  RETURN json;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.cleartopogeom(tg topogeometry)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  topology_info RECORD;
  sql TEXT;
BEGIN

  -- Get topology information
  SELECT id, name FROM topology.topology
    INTO topology_info
    WHERE id = topology_id(tg);
  IF NOT FOUND THEN
      RAISE EXCEPTION 'No topology with id "%" in topology.topology', topology_id(tg);
  END IF;

  -- Clear the TopoGeometry contents
  sql := 'DELETE FROM ' || quote_ident(topology_info.name)
        || '.relation WHERE layer_id = '
        || layer_id(tg)
        || ' AND topogeo_id = '
        || id(tg);
  EXECUTE sql;

  RETURN tg;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.copytopology(atopology character varying, newtopo character varying)
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  rec RECORD;
  rec2 RECORD;
  oldtopo_id integer;
  newtopo_id integer;
  n int4;
  ret text;
  sql text;
  useslargeids BOOLEAN := false;
BEGIN

  SELECT * FROM topology.topology where name = atopology
  INTO strict rec;
  oldtopo_id = rec.id;
  -- TODO: more gracefully handle unexistent topology

  -- Ensure useslargeids field is available
  IF to_jsonb(rec) ? 'useslargeids' THEN
    useslargeids := rec.useslargeids;
  END IF;

  SELECT topology.CreateTopology(newtopo, rec.SRID, rec.precision, rec.hasZ, 0, rec.useslargeids)
  INTO strict newtopo_id;

  sql := format(
    $$
      -- Copy faces
      INSERT INTO %1$I.face
      SELECT * FROM %2$I.face
      WHERE face_id != 0;

      -- Update face sequence
      SELECT setval(
        '%1$I.face_face_id_seq',
        (SELECT last_value FROM %2$I.face_face_id_seq)
      );

      -- Copy nodes
      INSERT INTO %1$I.node
      SELECT * FROM %2$I.node;

      -- Update node sequence
      SELECT setval(
        '%1$I.node_node_id_seq',
        (SELECT last_value FROM %2$I.node_node_id_seq)
      );

      -- Copy edges
      INSERT INTO %1$I.edge_data
      SELECT * FROM %2$I.edge_data;

      -- Update edge sequence
      SELECT setval(
        '%1$I.edge_data_edge_id_seq',
        (SELECT last_value FROM %2$I.edge_data_edge_id_seq)
      );
    $$,
    newtopo,
    atopology
  );
  EXECUTE sql;

  -- Copy layers and their TopoGeometry sequences
  -- and their TopoGeometry definitions, from primitives
  -- to hierarchical
  FOR rec IN
    SELECT * FROM topology.layer
    WHERE topology_id = oldtopo_id
    ORDER BY COALESCE(child_id, 0), layer_id
  LOOP
    INSERT INTO topology.layer (topology_id, layer_id, feature_type,
      level, child_id, schema_name, table_name, feature_column)
      VALUES (newtopo_id, rec.layer_id, rec.feature_type,
              rec.level, rec.child_id, newtopo,
              'LAYER' ||  rec.layer_id, '');

    -- Create layer's TopoGeometry sequences
    EXECUTE format(
      $$
        CREATE SEQUENCE %1$I.topogeo_s_%2$s;
        SELECT setval(
          '%1$I.topogeo_s_%2$s',
          (SELECT last_value FROM %3$I.topogeo_s_%2$s)
        );
      $$,
      newtopo,
      rec.layer_id,
      atopology
    );

    -- Copy TopoGeometry definitions
    EXECUTE format(
      $$
        INSERT INTO %1$I.relation
        SELECT * FROM %2$I.relation
        WHERE layer_id = $1
      $$,
      newtopo,
      atopology
    ) USING rec.layer_id;

  END LOOP;

  RETURN newtopo_id;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.createtopogeom(toponame character varying, tg_type integer, layer_id integer, tg_objs topoelementarray, tg_id bigint DEFAULT 0)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  i integer;
  dims varchar;
  outerdims varchar;
  innerdims varchar;
  obj_type integer;
  obj_id bigint;
  ret topology.TopoGeometry;
  rec RECORD;
  layertype integer;
  layerlevel integer;
  layerchild integer;
  cnt integer;
  sql TEXT;
BEGIN
  -- Check for negative
  IF tg_id < 0 THEN
    RAISE EXCEPTION 'Invalid Topogeo ID % (must be > 0)', tg_id;
  END IF;

  IF tg_type < 1 OR tg_type > 4 THEN
    RAISE EXCEPTION 'Invalid TopoGeometry type % (must be in the range 1..4)', tg_type;
  END IF;

  -- Get topology id into return TopoGeometry
  SELECT id INTO ret.topology_id
    FROM topology.topology WHERE name = toponame;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topology % does not exist', quote_literal(toponame);
  END IF;

  --
  -- Get layer info
  --
  layertype := NULL;
  FOR rec IN EXECUTE 'SELECT * FROM topology.layer'
       ' WHERE topology_id = ' || ret.topology_id
    || ' AND layer_id = ' || layer_id
  LOOP
    layertype = rec.feature_type;
    layerlevel = rec.level;
    layerchild = rec.child_id;
  END LOOP;

  -- Check for existence of given layer id
  IF layertype IS NULL THEN
    RAISE EXCEPTION 'No layer with id % is registered with topology %', layer_id, toponame;
  END IF;

  -- Verify compatibility between layer geometry type and
  -- TopoGeom requested geometry type
  IF layertype != 4 and layertype != tg_type THEN
    RAISE EXCEPTION 'A Layer of type % cannot contain a TopoGeometry of type %', layertype, tg_type;
  END IF;

  -- Set layer id and type in return object
  ret.layer_id = layer_id;
  ret.type = tg_type;

  --
  -- Get new TopoGeo id from sequence
  --
  FOR rec IN EXECUTE 'SELECT nextval(' ||
    quote_literal(
      quote_ident(toponame) || '.topogeo_s_' || layer_id
    ) || ')'
  LOOP
    ret.id = rec.nextval;
  END LOOP;

  IF tg_id > 0 THEN
    IF tg_id > ret.id THEN
      -- set sequence to match tg_id
      EXECUTE 'SELECT setval(' ||
        quote_literal(
          quote_ident(toponame) || '.topogeo_s_' || layer_id) || ', ' || tg_id ||
        ')' INTO STRICT ret.id;
    END IF;

    ret.id = tg_id;
  END IF;

  -- Loop over outer dimension
  i = array_lower(tg_objs, 1);
  LOOP
    obj_id = tg_objs[i][1];
    obj_type = tg_objs[i][2];

    -- Elements of type 0 represent emptiness, just skip them
    IF obj_type = 0 THEN
      IF obj_id != 0 THEN
        RAISE EXCEPTION 'Malformed empty topo element {0,%} -- id must be 0 as well', obj_id;
      END IF;
    ELSE
      IF layerlevel = 0 THEN -- array specifies lower-level objects
        IF tg_type != 4 and tg_type != obj_type THEN
          RAISE EXCEPTION 'A TopoGeometry of type % cannot contain topology elements of type %', tg_type, obj_type;
        END IF;
      ELSE -- array specifies lower-level topogeometries
        IF obj_type != layerchild THEN
          RAISE EXCEPTION 'TopoGeom element layer do not match TopoGeom child layer';
        END IF;
        -- TODO: verify that the referred TopoGeometry really
        -- exists in the relation table ?
      END IF;

      --RAISE NOTICE 'obj:% type:% id:%', i, obj_type, obj_id;

      --
      -- Insert record into the Relation table
      --
      EXECUTE 'INSERT INTO '||quote_ident(toponame)
        || '.relation(topogeo_id, layer_id, '
           'element_id,element_type) '
           ' VALUES ('||ret.id
        ||','||ret.layer_id
        || ',' || obj_id || ',' || obj_type || ');';
    END IF;

    i = i+1;
    IF i > array_upper(tg_objs, 1) THEN
      EXIT;
    END IF;
  END LOOP;

  RETURN ret;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.createtopogeom(toponame character varying, tg_type integer, layer_id integer)
 RETURNS topogeometry
 LANGUAGE sql
 STRICT
AS $function$
  SELECT topology.CreateTopoGeom($1,$2,$3,'{{0,0}}');
$function$
;

CREATE OR REPLACE FUNCTION topology.createtopology(atopology name, srid integer DEFAULT 0, prec double precision DEFAULT 0, hasz boolean DEFAULT false, topoid integer DEFAULT 0, useslargeids boolean DEFAULT false)
 RETURNS integer
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  rec RECORD;
  topology_id integer;
  sql TEXT;
  zsuffix TEXT := '';
  cnt integer;
  primaryColumnType TEXT := 'SERIAL';
  dataColumnType TEXT := 'INT4';
BEGIN

--  FOR rec IN SELECT * FROM pg_namespace WHERE text(nspname) = atopology
--  LOOP
--    RAISE EXCEPTION 'SQL/MM Spatial exception - schema already exists';
--  END LOOP;

  -- Prevent negative
  IF topoid < 0 THEN
    RAISE EXCEPTION 'Invalid Topology ID % (must be > 0)', topoid;
  END IF;

  IF hasZ THEN
    zsuffix := 'z';
  END IF;

  IF srid < 0 THEN
    RAISE NOTICE 'SRID value % converted to the officially unknown SRID value 0', srid;
    srid = 0;
  ELSIF srid = 0 THEN
    -- TODO: Does this need a notice. It will break a lot of tests
    srid = ST_SRID('POINT EMPTY'::geometry);
  END IF;

  topology_id := nextval('topology.topology_id_seq');

  IF topoid > 0 THEN
    ------ Check if the ID has been used already
    SELECT count(*)
    INTO cnt
    FROM topology.topology
    WHERE id = topoid;
    -- RAISE INFO 'cnt: %', cnt;

    IF cnt > 0
    THEN
      RAISE EXCEPTION 'topology with id % already exists', topoid;
    END IF;

    -- set sequence to match topoid
    IF topoid > topology_id THEN
      SELECT setval('topology.topology_id_seq', topoid) INTO topology_id;
    END IF;

    topology_id := topoid;
  END IF;

  IF usesLargeIDs THEN
    primaryColumnType := 'BIGSERIAL';
    dataColumnType := 'INT8';
  END IF;

  sql := format(
    $$
      CREATE SCHEMA %1$I;

      -------------{ face CREATION
      CREATE TABLE %1$I.face(
        face_id %5$s,
        mbr GEOMETRY(polygon, %2$L), -- 2d only mbr is good enough
        CONSTRAINT face_primary_key
        PRIMARY KEY(face_id)
      );

      -- Face standard view description
      COMMENT ON TABLE %1$I.face IS
      'Contains face topology primitives';

      -------------} END OF face CREATION

      --------------{ node CREATION

      CREATE TABLE %1$I.node(
        node_id %5$s,
        containing_face %6$s,
        geom GEOMETRY(point%3$s, %2$L),
        CONSTRAINT node_primary_key
          PRIMARY KEY(node_id),
        CONSTRAINT face_exists
          FOREIGN KEY(containing_face)
          REFERENCES %1$I.face(face_id)
      );

      -- Node standard view description
      COMMENT ON TABLE %1$I.node IS
      'Contains node topology primitives';

      ------- Add index on containing_face, to speed up
      ------- topology editing (adding/removing faces)
      ------- See http://trac.osgeo.org/postgis/ticket/2861
      CREATE INDEX node_containing_face_idx
        ON %1$I.node (containing_face);

      --------------} END OF node CREATION

      --------------{ edge CREATION

      -- edge_data table
      CREATE TABLE %1$I.edge_data (
        edge_id %5$s NOT NULL PRIMARY KEY,
        start_node %6$s NOT NULL,
        end_node %6$s NOT NULL,
        next_left_edge %6$s NOT NULL,
        abs_next_left_edge %6$s NOT NULL,
        next_right_edge %6$s NOT NULL,
        abs_next_right_edge %6$s NOT NULL,
        left_face %6$s NOT NULL,
        right_face %6$s NOT NULL,
        geom GEOMETRY(linestring%3$s, %2$L) NOT NULL,

        CONSTRAINT start_node_exists
          FOREIGN KEY(start_node)
          REFERENCES %1$I.node(node_id),

        CONSTRAINT end_node_exists
          FOREIGN KEY(end_node)
          REFERENCES %1$I.node(node_id),

        CONSTRAINT left_face_exists
          FOREIGN KEY(left_face)
          REFERENCES %1$I.face(face_id),

        CONSTRAINT right_face_exists
          FOREIGN KEY(right_face)
          REFERENCES %1$I.face(face_id),

        CONSTRAINT next_left_edge_exists
          FOREIGN KEY(abs_next_left_edge)
          REFERENCES %1$I.edge_data(edge_id)
          DEFERRABLE INITIALLY DEFERRED,

        CONSTRAINT next_right_edge_exists
          FOREIGN KEY(abs_next_right_edge)
          REFERENCES %1$I.edge_data(edge_id)
          DEFERRABLE INITIALLY DEFERRED
      );

      -- edge standard view (select rule)
      CREATE VIEW %1$I.edge AS
      SELECT
        edge_id, start_node, end_node, next_left_edge,
        next_right_edge, left_face, right_face, geom
      FROM %1$I.edge_data;

      -- Edge standard view description
      COMMENT ON VIEW %1$I.edge IS
      'Contains edge topology primitives';
      COMMENT ON COLUMN %1$I.edge.edge_id IS
      'Unique identifier of the edge';
      COMMENT ON COLUMN %1$I.edge.start_node IS
      'Unique identifier of the node at the start of the edge';
      COMMENT ON COLUMN %1$I.edge.end_node IS
      'Unique identifier of the node at the end of the edge';
      COMMENT ON COLUMN %1$I.edge.next_left_edge IS
      'Unique identifier of the next edge of the face on the left (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';
      COMMENT ON COLUMN %1$I.edge.next_right_edge IS
      'Unique identifier of the next edge of the face on the right (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';
      COMMENT ON COLUMN %1$I.edge.left_face IS
      'Unique identifier of the face on the left side of the edge when looking in the direction from START_NODE to END_NODE';
      COMMENT ON COLUMN %1$I.edge.right_face IS
      'Unique identifier of the face on the right side of the edge when looking in the direction from START_NODE to END_NODE';
      COMMENT ON COLUMN %1$I.edge.geom IS
      'The geometry of the edge';

      -- edge standard view (insert rule)
      CREATE RULE edge_insert_rule AS
      ON INSERT TO %1$I.edge
      DO INSTEAD INSERT into %1$I.edge_data
      VALUES (
        NEW.edge_id, NEW.start_node, NEW.end_node,
        NEW.next_left_edge, abs(NEW.next_left_edge),
        NEW.next_right_edge, abs(NEW.next_right_edge),
        NEW.left_face, NEW.right_face, NEW.geom
      );

      ------- Add support indices supporting edge linking foreign keys
      ------- See https://trac.osgeo.org/postgis/ticket/2083#comment:20
      CREATE INDEX ON %1$I.edge_data(abs_next_left_edge);
      CREATE INDEX ON %1$I.edge_data(abs_next_right_edge);

      --------------} END OF edge CREATION

      --------------{ layer sequence
      CREATE SEQUENCE %1$I.layer_id_seq;
      --------------} layer sequence

      --------------{ relation CREATION
      CREATE TABLE %1$I.relation (
        topogeo_id %6$s NOT NULL,
        layer_id integer NOT NULL,
        element_id %6$s NOT NULL,
        element_type integer NOT NULL,
        UNIQUE(layer_id,topogeo_id,element_id,element_type)
      );
      ------- Add index on element_type, element_id to speed up
      ------- queries looking for TopoGeometries using specific
      ------- primitive elements of the topology
      ------- See http://trac.osgeo.org/postgis/ticket/2083
      CREATE INDEX relation_element_id_idx
        ON %1$I.relation (element_id);

      CREATE TRIGGER relation_integrity_checks
      BEFORE UPDATE OR INSERT ON %1$I.relation
      FOR EACH ROW EXECUTE PROCEDURE
      topology.RelationTrigger(%4$L, %1$L);
      --------------} END OF relation CREATION

      ------- Default (world) face
      INSERT INTO %1$I.face(face_id) VALUES(0);

      ------- GiST index on face
      CREATE INDEX face_gist ON %1$I.face
      USING gist (mbr);

      ------- GiST index on node
      CREATE INDEX node_gist ON %1$I.node
      USING gist (geom);

      ------- GiST index on edge
      CREATE INDEX edge_gist ON %1$I.edge_data
      USING gist (geom);

      ------- Indexes on left_face and right_face of edge_data
      ------- NOTE: these indexes speed up GetFaceGeometry (and thus
      -------       TopoGeometry::Geometry) by a factor of 10 !
      -------       See http://trac.osgeo.org/postgis/ticket/806
      CREATE INDEX edge_left_face_idx
        ON %1$I.edge_data (left_face);
      CREATE INDEX edge_right_face_idx
        ON %1$I.edge_data (right_face);

      ------- Indexes on start_node and end_node of edge_data
      ------- NOTE: this indexes speed up node deletion
      -------       by a factor of 1000 !
      -------       See http://trac.osgeo.org/postgis/ticket/2082
      CREATE INDEX edge_start_node_idx
        ON %1$I.edge_data (start_node);
      CREATE INDEX edge_end_node_idx
        ON %1$I.edge_data (end_node);

      -- TODO: consider also adding an index on node.containing_face

    $$,
    atopology,          -- %1
    srid,               -- %2
    zsuffix,            -- %3
    topology_id,        -- %4
    primaryColumnType,  -- %5
    dataColumnType      -- %6
  );
  EXECUTE sql;

  ------- Add record to the "topology" metadata table
  INSERT INTO topology.topology (id, name, srid, precision, hasZ, usesLargeIds)
  VALUES (topology_id, atopology, srid, prec, hasZ, usesLargeIDs);

  RETURN topology_id;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.droptopogeometrycolumn(schema character varying, tbl character varying, col character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  rec RECORD;
  lyrinfo RECORD;
  ok BOOL;
  result text;
  sql TEXT;
BEGIN

  -- Get layer and topology info

  sql := $$
    SELECT t.name as toponame, l.*
    FROM topology.topology t, topology.layer l
    WHERE l.topology_id = t.id
    AND l.schema_name = $1
    AND l.table_name = $2
    AND l.feature_column = $3
  $$;

  ok := false;
  FOR rec IN EXECUTE sql USING schema, tbl, col
  LOOP
    ok := true;
    lyrinfo := rec;
  END LOOP;

  -- Layer not found
  IF NOT ok THEN
    RAISE EXCEPTION 'No layer registered on %.%.%',
      schema,tbl,col;
  END IF;

  -- Cleanup the relation table (if it exists)
  BEGIN
    sql := format(
      'DELETE FROM %I.relation WHERE layer_id = $1',
      lyrinfo.toponame
    );
    EXECUTE sql USING lyrinfo.layer_id;
  EXCEPTION
    WHEN UNDEFINED_TABLE THEN
      RAISE NOTICE '%', SQLERRM;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Got % (%)', SQLERRM, SQLSTATE;
  END;

  -- Drop the sequence for topogeoms in this layer
  sql := format(
    'DROP SEQUENCE IF EXISTS %I.topogeo_s_%s',
    lyrinfo.toponame,
    lyrinfo.layer_id
  );
  EXECUTE sql;

  ok = false;
  FOR rec IN SELECT * FROM pg_namespace n, pg_class c, pg_attribute a
    WHERE text(n.nspname) = schema
    AND c.relnamespace = n.oid
    AND text(c.relname) = tbl
    AND a.attrelid = c.oid
    AND text(a.attname) = col
  LOOP
    ok = true;
    EXIT;
  END LOOP;

  IF ok THEN
    -- Drop the layer column
    sql := format(
      'ALTER TABLE %I.%I DROP %I CASCADE',
      schema, tbl, col
    );
    EXECUTE sql;
  END IF;

  -- Delete the layer record
  sql := $$
    DELETE FROM topology.layer
    WHERE topology_id = $1
    AND layer_id = $2
  $$;
  EXECUTE sql USING lyrinfo.topology_id, lyrinfo.layer_id;


  result := format(
    'Layer %s (%I.%I.%I) dropped',
    lyrinfo.layer_id, schema, tbl, col
  );

  RETURN result;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.droptopology(atopology character varying)
 RETURNS text
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  topoid integer;
  rec RECORD;
  sql TEXT;
  toposchema REGNAMESPACE;
  deferred_constraints TEXT[];
BEGIN
  -- Get topology id
  SELECT id INTO topoid
    FROM topology.topology WHERE name = atopology;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topology % does not exist', quote_literal(atopology);
  END IF;

  RAISE NOTICE 'Dropping all layers from topology % (%)',
    quote_literal(atopology), topoid;

  -- Drop all layers in the topology
  sql := 'SELECT * FROM topology.layer WHERE topology_id = $1';
  FOR rec IN EXECUTE sql USING topoid
  LOOP

    sql := format(
      'SELECT topology.DropTopoGeometryColumn(%L, %L, %L)',
      rec.schema_name, rec.table_name, rec.feature_column
    );
    EXECUTE sql;
  END LOOP;


  -- Delete record from topology.topology
  sql := 'DELETE FROM topology.topology WHERE id = $1';
  EXECUTE sql USING topoid;


  -- Drop the schema (if it exists)
  SELECT oid FROM pg_namespace WHERE text(nspname) = atopology
  INTO toposchema;

  IF toposchema IS NOT NULL THEN --{

    -- Give immediate execution to pending constraints
    -- in the topology schema.
    --
    -- See https://trac.osgeo.org/postgis/ticket/5115
    SELECT array_agg(format('%I.%I', atopology, conname))
    FROM pg_constraint c
    WHERE connamespace = toposchema AND condeferred
    INTO deferred_constraints;

    IF deferred_constraints IS NOT NULL THEN --{
      sql := format(
        'SET constraints %s IMMEDIATE',
        array_to_string(deferred_constraints, ',')
      );
      EXECUTE sql;
    END IF; --}

    sql := format('DROP SCHEMA %I CASCADE', atopology);
    EXECUTE sql;
  END IF; --}

  RETURN format('Topology %L dropped', atopology);
END
$function$
;

CREATE OR REPLACE FUNCTION topology.equals(tg1 topogeometry, tg2 topogeometry)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  rec RECORD;
  toponame varchar;
  query text;
BEGIN

  IF tg1.topology_id != tg2.topology_id THEN
    -- TODO: revert to ::geometry instead ?
    RAISE EXCEPTION 'Cannot compare TopoGeometries from different topologies';
  END IF;

  -- Not the same type, not equal
  IF tg1.type != tg2.type THEN
    RETURN FALSE;
  END IF;

  -- Geometry collection are not currently supported
  IF tg2.type = 4 THEN
    RAISE EXCEPTION 'GeometryCollection are not supported by equals()';
  END IF;

        -- Get topology name
        SELECT name FROM topology.topology into toponame
                WHERE id = tg1.topology_id;

  -- Two geometries are equal if they are composed by
  -- the same TopoElements
  FOR rec IN EXECUTE 'SELECT * FROM '
    || ' topology.GetTopoGeomElements('
    || quote_literal(toponame) || ', '
    || tg1.layer_id || ',' || tg1.id || ') '
    || ' EXCEPT SELECT * FROM '
    || ' topology.GetTopogeomElements('
    || quote_literal(toponame) || ', '
    || tg2.layer_id || ',' || tg2.id || ');'
  LOOP
    RETURN FALSE;
  END LOOP;

  FOR rec IN EXECUTE 'SELECT * FROM '
    || ' topology.GetTopoGeomElements('
    || quote_literal(toponame) || ', '
    || tg2.layer_id || ',' || tg2.id || ')'
    || ' EXCEPT SELECT * FROM '
    || ' topology.GetTopogeomElements('
    || quote_literal(toponame) || ', '
    || tg1.layer_id || ',' || tg1.id || '); '
  LOOP
    RETURN FALSE;
  END LOOP;
  RETURN TRUE;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.findlayer(tg topogeometry)
 RETURNS layer
 LANGUAGE sql
AS $function$
    SELECT * FROM topology.layer
    WHERE topology_id = topology_id($1)
    AND layer_id = layer_id($1)
$function$
;

CREATE OR REPLACE FUNCTION topology.findlayer(layer_table regclass, feature_column name)
 RETURNS layer
 LANGUAGE sql
AS $function$
    SELECT l.*
    FROM topology.layer l, pg_class c, pg_namespace n
    WHERE l.schema_name = n.nspname
    AND l.table_name = c.relname
    AND c.oid = $1
    AND c.relnamespace = n.oid
    AND l.feature_column = $2
$function$
;

CREATE OR REPLACE FUNCTION topology.findlayer(schema_name name, table_name name, feature_column name)
 RETURNS layer
 LANGUAGE sql
AS $function$
    SELECT * FROM topology.layer
    WHERE schema_name = $1
    AND table_name = $2
    AND feature_column = $3;
$function$
;

CREATE OR REPLACE FUNCTION topology.findlayer(topology_id integer, layer_id integer)
 RETURNS layer
 LANGUAGE sql
AS $function$
    SELECT * FROM topology.layer
    WHERE topology_id = $1
      AND layer_id = $2
$function$
;

CREATE OR REPLACE FUNCTION topology.findtopology(topogeometry)
 RETURNS topology
 LANGUAGE sql
AS $function$
    SELECT * FROM topology.topology
    WHERE id = topology_id($1);
$function$
;

CREATE OR REPLACE FUNCTION topology.findtopology(regclass, name)
 RETURNS topology
 LANGUAGE sql
AS $function$
    SELECT t.*
    FROM topology.topology t
    JOIN topology.layer l ON (t.id = l.topology_id)
    WHERE format('%I.%I', l.schema_name, l.table_name)::regclass = $1
    AND l.feature_column = $2;
$function$
;

CREATE OR REPLACE FUNCTION topology.findtopology(name, name, name)
 RETURNS topology
 LANGUAGE sql
AS $function$
    SELECT t.*
    FROM topology.topology t
    JOIN topology.layer l ON (t.id = l.topology_id)
    WHERE l.schema_name = $1
    AND l.table_name = $2
    AND l.feature_column = $3;
$function$
;

CREATE OR REPLACE FUNCTION topology.findtopology(text)
 RETURNS topology
 LANGUAGE sql
AS $function$
    SELECT *
    FROM topology.topology
    WHERE name = $1
$function$
;

CREATE OR REPLACE FUNCTION topology.findtopology(integer)
 RETURNS topology
 LANGUAGE sql
AS $function$
    SELECT *
    FROM topology.topology
    WHERE id = $1
$function$
;

CREATE OR REPLACE FUNCTION topology.geometry(topogeom topogeometry)
 RETURNS geometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  toponame varchar;
  toposrid INT;
  geom geometry;
  elements_count INT;
  rec RECORD;
  plyr RECORD;
  clyr RECORD;
  sql TEXT;
BEGIN

  -- Get topology name
  SELECT name, srid FROM topology.topology
  WHERE id = topogeom.topology_id
  INTO toponame, toposrid;
  IF toponame IS NULL THEN
    RAISE EXCEPTION 'Invalid TopoGeometry (unexistent topology id %)', topogeom.topology_id;
  END IF;

  -- Get layer info
  SELECT * FROM topology.layer
    WHERE topology_id = topogeom.topology_id
    AND layer_id = topogeom.layer_id
    INTO plyr;
  IF plyr IS NULL THEN
    RAISE EXCEPTION 'Could not find TopoGeometry layer % in topology %', topogeom.layer_id, topogeom.topology_id;
  END IF;

  --
  -- If this feature layer is on any level > 0 we will
  -- compute the topological union of all child features
  -- in fact recursing.
  --
  IF plyr.level > 0 THEN -- {

    -- Get child layer info
    SELECT * FROM topology.layer WHERE layer_id = plyr.child_id
      AND topology_id = topogeom.topology_id
      INTO clyr;
    IF clyr IS NULL THEN
      RAISE EXCEPTION 'Invalid layer % in topology % (unexistent child layer %)', topogeom.layer_id, topogeom.topology_id, plyr.child_id;
    END IF;

    sql := 'SELECT st_multi(st_union(topology.Geometry('
      || quote_ident(clyr.feature_column)
      || '))) as geom FROM '
      || quote_ident(clyr.schema_name) || '.'
      || quote_ident(clyr.table_name)
      || ', ' || quote_ident(toponame) || '.relation pr'
         ' WHERE '
         ' pr.topogeo_id = ' || topogeom.id
      || ' AND '
         ' pr.layer_id = ' || topogeom.layer_id
      || ' AND '
         ' id('||quote_ident(clyr.feature_column)
      || ') = pr.element_id '
         ' AND '
         'layer_id('||quote_ident(clyr.feature_column)
      || ') = pr.element_type ';
    --RAISE DEBUG '%', query;
    EXECUTE sql INTO geom;

  ELSIF topogeom.type = 3 THEN -- [multi]polygon -- }{

    sql := format(
      $$
SELECT
  count(element_id),
  ST_Multi(
    ST_Union(
      topology.ST_GetFaceGeometry(
        %1$L,
        element_id
      )
    )
  ) as g
FROM %1$I.relation
WHERE topogeo_id = %2$L
AND layer_id = %3$L
AND element_type = 3
      $$,
      toponame,
      topogeom.id,
      topogeom.layer_id
    );
    EXECUTE sql INTO elements_count, geom;


  ELSIF topogeom.type = 2 THEN -- [multi]line -- }{

    sql := format(
      $$
SELECT
  st_multi(
    ST_LineMerge(
      ST_Collect(
        CASE
          WHEN r.element_id > 0 THEN
            e.geom
          ELSE
            ST_Reverse(e.geom)
        END
      )
    )
  ) as g
FROM %1$I.edge e, %1$I.relation r
WHERE r.topogeo_id = id($1)
AND r.layer_id = layer_id($1)
AND r.element_type = 2
AND abs(r.element_id) = e.edge_id
      $$,
      toponame
    );
    EXECUTE sql USING topogeom INTO geom;

  ELSIF topogeom.type = 1 THEN -- [multi]point -- }{

    sql :=
      'SELECT st_multi(st_union(n.geom)) as g FROM '
      || quote_ident(toponame) || '.node n, '
      || quote_ident(toponame) || '.relation r '
         ' WHERE r.topogeo_id = ' || topogeom.id
      || ' AND r.layer_id = ' || topogeom.layer_id
      || ' AND r.element_type = 1 '
         ' AND r.element_id = n.node_id';
    EXECUTE sql INTO geom;

  ELSIF topogeom.type = 4 THEN -- mixed collection -- }{

    sql := 'WITH areas AS ( SELECT ST_Union('
         'topology.ST_GetFaceGeometry('
      || quote_literal(toponame) || ','
      || 'element_id)) as g FROM '
      || quote_ident(toponame)
      || '.relation WHERE topogeo_id = '
      || topogeom.id || ' AND layer_id = '
      || topogeom.layer_id || ' AND element_type = 3), '
         'lines AS ( SELECT ST_LineMerge(ST_Collect(e.geom)) as g FROM '
      || quote_ident(toponame) || '.edge e, '
      || quote_ident(toponame) || '.relation r '
         ' WHERE r.topogeo_id = ' || topogeom.id
      || ' AND r.layer_id = ' || topogeom.layer_id
      || ' AND r.element_type = 2 '
         ' AND abs(r.element_id) = e.edge_id ), '
         ' points as ( SELECT st_union(n.geom) as g FROM '
      || quote_ident(toponame) || '.node n, '
      || quote_ident(toponame) || '.relation r '
         ' WHERE r.topogeo_id = ' || topogeom.id
      || ' AND r.layer_id = ' || topogeom.layer_id
      || ' AND r.element_type = 1 '
         ' AND r.element_id = n.node_id ), '
         ' un as ( SELECT g FROM areas UNION ALL SELECT g FROM lines '
         '          UNION ALL SELECT g FROM points ) '
         'SELECT ST_Multi(ST_Collect(g)) FROM un';
    EXECUTE sql INTO geom;

  ELSE -- }{

    RAISE EXCEPTION 'Invalid TopoGeometries (unknown type %)', topogeom.type;

  END IF; -- }

  IF geom IS NULL THEN
    IF topogeom.type = 3 THEN -- [multi]polygon
      geom := 'MULTIPOLYGON EMPTY';
    ELSIF topogeom.type = 2 THEN -- [multi]line
      geom := 'MULTILINESTRING EMPTY';
    ELSIF topogeom.type = 1 THEN -- [multi]point
      geom := 'MULTIPOINT EMPTY';
    ELSE
      geom := 'GEOMETRYCOLLECTION EMPTY';
    END IF;
    geom := ST_SetSRID(geom, toposrid);
  END IF;

  RETURN geom;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.geometrytype(tg topogeometry)
 RETURNS text
 LANGUAGE sql
 STABLE STRICT
AS $function$
	SELECT CASE
		WHEN type($1) = 1 THEN 'MULTIPOINT'
		WHEN type($1) = 2 THEN 'MULTILINESTRING'
		WHEN type($1) = 3 THEN 'MULTIPOLYGON'
		WHEN type($1) = 4 THEN 'GEOMETRYCOLLECTION'
		ELSE 'UNEXPECTED'
		END;
$function$
;

CREATE OR REPLACE FUNCTION topology.getedgebypoint(atopology character varying, apoint geometry, tol1 double precision)
 RETURNS bigint
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis_topology-3', $function$GetEdgeByPoint$function$
;

CREATE OR REPLACE FUNCTION topology.getfacebypoint(atopology character varying, apoint geometry, tol1 double precision)
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  rec RECORD;
  sql TEXT;
  sideFaces BIGINT[];
BEGIN

  -- Check if any edge intersects the query circle
  sql := format(
    $$
      WITH edges_in_circle AS (
        SELECT
          left_face,
          right_face
        FROM
          %1$I.edge
        WHERE
          ST_DWithin(geom, $1, $2)
      ), side_faces AS (
        SELECT left_face f FROM edges_in_circle
          UNION
        SELECT right_face FROM edges_in_circle
      )
      SELECT array_agg(f ORDER BY f) FROM side_faces;
    $$,
    atopology
  );
  EXECUTE sql
  USING apoint, tol1
  INTO sideFaces;

  RAISE DEBUG 'Side faces: %', sideFaces;

  IF array_upper(sideFaces, 1) = 1
  THEN
    -- Edges intersecting the circle
    -- have a single side-face, our circle
    -- is surely in that face
    --
    -- NOTE: this may also be the universe face
    --
    RETURN sideFaces[1];
  END IF;

  IF array_upper(sideFaces, 1) = 2
  THEN
    IF sideFaces[1] = 0
    THEN
      -- Edges intersecting the circle
      -- have a single real side-face,
      -- we'll consider our query to be in that face
      RETURN sideFaces[2];
    ELSE
      -- Edges have multiple real side-faces
      RAISE EXCEPTION 'Two or more faces found';
    END IF;
  END IF;

  IF array_upper(sideFaces, 1) > 2
  THEN
      RAISE EXCEPTION 'Two or more faces found';
  END IF;

  -- No edge intersects the circle, check for containment
  RETURN topology.GetFaceContainingPoint(atopology, apoint);
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.getfacecontainingpoint(atopology text, apoint geometry)
 RETURNS bigint
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis_topology-3', $function$GetFaceContainingPoint$function$
;

CREATE OR REPLACE FUNCTION topology.getnodebypoint(atopology character varying, apoint geometry, tol1 double precision)
 RETURNS bigint
 LANGUAGE c
 STABLE STRICT
AS '$libdir/postgis_topology-3', $function$GetNodeByPoint$function$
;

CREATE OR REPLACE FUNCTION topology.getnodeedges(atopology character varying, anode bigint)
 RETURNS SETOF getfaceedges_returntype
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  curedge bigint;
  nextedge bigint;
  rec RECORD;
  retrec topology.GetFaceEdges_ReturnType;
  n int;
  sql text;
BEGIN

  n := 0;
  sql := format(
    $$
      WITH incident_edges AS (
        SELECT
          edge_id,
          start_node,
          end_node,
          ST_RemoveRepeatedPoints(geom) as geom
        FROM %1$I.edge_data
        WHERE start_node = $1
        or end_node = $1
      )
      SELECT
        edge_id,
        ST_Azimuth(ST_StartPoint(geom), ST_PointN(geom, 2)) as az
      FROM incident_edges
      WHERE start_node = $1
        UNION ALL
      SELECT
        -edge_id,
        ST_Azimuth(ST_EndPoint(geom), ST_PointN(geom, ST_NumPoints(geom)-1))
      FROM incident_edges
      WHERE end_node = $1
      ORDER BY az
    $$,
    atopology
  );

  FOR rec IN EXECUTE sql USING anode
  LOOP -- incident edges {

    n := n + 1;
    retrec.sequence := n;
    retrec.edge := rec.edge_id;
    RETURN NEXT retrec;
  END LOOP; -- incident edges }

END
$function$
;

CREATE OR REPLACE FUNCTION topology.getringedges(atopology character varying, anedge bigint, maxedges integer DEFAULT NULL::integer)
 RETURNS SETOF getfaceedges_returntype
 LANGUAGE c
 STABLE
AS '$libdir/postgis_topology-3', $function$GetRingEdges$function$
;

CREATE OR REPLACE FUNCTION topology.gettopogeomelementarray(toponame character varying, layer_id integer, tgid bigint)
 RETURNS topoelementarray
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  rec RECORD;
  tg_objs varchar := '{';
  i integer;
  query text;
BEGIN

  query = 'SELECT * FROM topology.GetTopoGeomElements('
    || quote_literal(toponame) || ','
    || quote_literal(layer_id) || ','
    || quote_literal(tgid)
    || ') as obj ORDER BY obj';


  -- TODO: why not using array_agg here ?

  i = 1;
  FOR rec IN EXECUTE query
  LOOP
    IF i > 1 THEN
      tg_objs = tg_objs || ',';
    END IF;
    tg_objs = tg_objs || '{'
      || rec.obj[1] || ',' || rec.obj[2]
      || '}';
    i = i+1;
  END LOOP;

  tg_objs = tg_objs || '}';

  RETURN tg_objs;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopogeomelementarray(tg topogeometry)
 RETURNS topoelementarray
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  toponame varchar;
BEGIN
  toponame = topology.GetTopologyName(tg.topology_id);
  RETURN topology.GetTopoGeomElementArray(toponame, tg.layer_id, tg.id);
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopogeomelements(toponame character varying, layerid integer, tgid bigint)
 RETURNS SETOF topoelement
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  ret topology.TopoElement;
  rec RECORD;
  rec2 RECORD;
  query text;
  query2 text;
  lyr RECORD;
  ok bool;
  topoid INTEGER;
BEGIN

  -- Get topology id
  SELECT id INTO topoid
    FROM topology.topology WHERE name = toponame;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topology % does not exist', quote_literal(toponame);
  END IF;

  -- Get layer info
  ok = false;
  FOR rec IN EXECUTE 'SELECT * FROM topology.layer '
       ' WHERE layer_id = $1 AND topology_id = $2'
       USING layerid, topoid
  LOOP
    lyr = rec;
    ok = true;
  END LOOP;

  IF NOT ok THEN
    RAISE EXCEPTION 'Layer % does not exist', layerid;
  END IF;

  query = 'SELECT abs(element_id) as element_id, element_type FROM '
    || quote_ident(toponame) || '.relation WHERE '
       ' layer_id = ' || layerid
    || ' AND topogeo_id = ' || quote_literal(tgid)
    || ' ORDER BY element_type, element_id';

  --RAISE NOTICE 'Query: %', query;

  FOR rec IN EXECUTE query
  LOOP
    IF lyr.level > 0 THEN
      query2 = 'SELECT * from topology.GetTopoGeomElements('
        || quote_literal(toponame) || ','
        || rec.element_type
        || ','
        || rec.element_id
        || ') as ret;';
      --RAISE NOTICE 'Query2: %', query2;
      FOR rec2 IN EXECUTE query2
      LOOP
        RETURN NEXT rec2.ret;
      END LOOP;
    ELSE
      ret = '{' || rec.element_id || ',' || rec.element_type || '}';
      RETURN NEXT ret::int8[];
    END IF;

  END LOOP;

  RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopogeomelements(tg topogeometry)
 RETURNS SETOF topoelement
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  toponame varchar;
  rec RECORD;
BEGIN
  toponame = topology.GetTopologyName(tg.topology_id);
  FOR rec IN SELECT * FROM topology.GetTopoGeomElements(toponame,
    tg.layer_id,tg.id) as ret
  LOOP
    RETURN NEXT rec.ret;
  END LOOP;
  RETURN;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopologyid(toponame character varying)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  ret integer;
BEGIN
  SELECT id INTO ret
    FROM topology.topology WHERE name = toponame;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Topology % does not exist', quote_literal(toponame);
  END IF;

  RETURN ret;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopologyname(topoid integer)
 RETURNS character varying
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  ret varchar;
BEGIN
        SELECT name FROM topology.topology into ret
                WHERE id = topoid;
  RETURN ret;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.gettopologysrid(toponame character varying)
 RETURNS integer
 LANGUAGE sql
 STABLE STRICT
AS $function$
  SELECT SRID FROM topology.topology WHERE name = $1;
$function$
;

CREATE OR REPLACE FUNCTION topology.intersects(tg1 topogeometry, tg2 topogeometry)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  tgbuf topology.TopoGeometry;
  rec RECORD;
  toponame varchar;
  query text;
BEGIN
  IF tg1.topology_id != tg2.topology_id THEN
    -- TODO: revert to ::geometry instead ?
    RAISE EXCEPTION 'Cannot compute intersection between TopoGeometries from different topologies';
  END IF;

  -- Order TopoGeometries so that tg1 has less-or-same
  -- dimensionality of tg1 (point,line,polygon,collection)
  IF tg1.type > tg2.type THEN
    tgbuf := tg2;
    tg2 := tg1;
    tg1 := tgbuf;
  END IF;

  --RAISE NOTICE 'tg1.id:% tg2.id:%', tg1.id, tg2.id;
  -- Geometry collection are not currently supported
  IF tg2.type = 4 THEN
    RAISE EXCEPTION 'GeometryCollection are not supported by intersects()';
  END IF;

        -- Get topology name
        SELECT name FROM topology.topology into toponame
                WHERE id = tg1.topology_id;

  -- Hierarchical TopoGeometries are not currently supported
  query = 'SELECT level FROM topology.layer'
    || ' WHERE '
    || ' topology_id = ' || tg1.topology_id
    || ' AND '
    || '( layer_id = ' || tg1.layer_id
    || ' OR layer_id = ' || tg2.layer_id
    || ' ) '
    || ' AND level > 0 ';

  --RAISE NOTICE '%', query;

  FOR rec IN EXECUTE query
  LOOP
    -- TODO: revert to ::geometry instead ?
    RAISE EXCEPTION 'Hierarchical TopoGeometries are not currently supported by intersects()';
  END LOOP;

  IF tg1.type = 1 THEN -- [multi]point

    IF tg2.type = 1 THEN -- point/point
  ---------------------------------------------------------
  --
  --  Two [multi]point features intersect if they share
  --  any Node
  --
  --
  --
      query =
        'SELECT a.topogeo_id FROM '
        || quote_ident(toponame) ||
        '.relation a, '
        || quote_ident(toponame) ||
        '.relation b '
        || 'WHERE a.layer_id = ' || tg1.layer_id
        || ' AND b.layer_id = ' || tg2.layer_id
        || ' AND a.topogeo_id = ' || tg1.id
        || ' AND b.topogeo_id = ' || tg2.id
        || ' AND a.element_id = b.element_id '
        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        RETURN TRUE; -- they share an element
      END LOOP;
      RETURN FALSE; -- no elements shared
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 2 THEN -- point/line
  ---------------------------------------------------------
  --
  --  A [multi]point intersects a [multi]line if they share
  --  any Node.
  --
  --
  --
      query =
        'SELECT a.topogeo_id FROM '
        || quote_ident(toponame) ||
        '.relation a, '
        || quote_ident(toponame) ||
        '.relation b, '
        || quote_ident(toponame) ||
        '.edge_data e '
        || 'WHERE a.layer_id = ' || tg1.layer_id
        || ' AND b.layer_id = ' || tg2.layer_id
        || ' AND a.topogeo_id = ' || tg1.id
        || ' AND b.topogeo_id = ' || tg2.id
        || ' AND abs(b.element_id) = e.edge_id '
        || ' AND ( '
          || ' e.start_node = a.element_id '
          || ' OR '
          || ' e.end_node = a.element_id '
        || ' )'
        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        RETURN TRUE; -- they share an element
      END LOOP;
      RETURN FALSE; -- no elements shared
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 3 THEN -- point/polygon
  ---------------------------------------------------------
  --
  --  A [multi]point intersects a [multi]polygon if any
  --  Node of the point is contained in any face of the
  --  polygon OR ( is end_node or start_node of any edge
  --  of any polygon face ).
  --
  --  We assume the Node-in-Face check is faster because
  --  there will be less Faces then Edges in any polygon.
  --
  --
  --
  --
      -- Check if any node is contained in a face
      query =
        'SELECT n.node_id as id FROM '
        || quote_ident(toponame) ||
        '.relation r1, '
        || quote_ident(toponame) ||
        '.relation r2, '
        || quote_ident(toponame) ||
        '.node n '
        || 'WHERE r1.layer_id = ' || tg1.layer_id
        || ' AND r2.layer_id = ' || tg2.layer_id
        || ' AND r1.topogeo_id = ' || tg1.id
        || ' AND r2.topogeo_id = ' || tg2.id
        || ' AND n.node_id = r1.element_id '
        || ' AND r2.element_id = n.containing_face '
        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        --RAISE NOTICE 'Node % in polygon face', rec.id;
        RETURN TRUE; -- one (or more) nodes are
                     -- contained in a polygon face
      END LOOP;

      -- Check if any node is start or end of any polygon
      -- face edge
      query =
        'SELECT n.node_id as nid, e.edge_id as eid '
        || ' FROM '
        || quote_ident(toponame) ||
        '.relation r1, '
        || quote_ident(toponame) ||
        '.relation r2, '
        || quote_ident(toponame) ||
        '.edge_data e, '
        || quote_ident(toponame) ||
        '.node n '
        || 'WHERE r1.layer_id = ' || tg1.layer_id
        || ' AND r2.layer_id = ' || tg2.layer_id
        || ' AND r1.topogeo_id = ' || tg1.id
        || ' AND r2.topogeo_id = ' || tg2.id
        || ' AND n.node_id = r1.element_id '
        || ' AND ( '
        || ' e.left_face = r2.element_id '
        || ' OR '
        || ' e.right_face = r2.element_id '
        || ' ) '
        || ' AND ( '
        || ' e.start_node = r1.element_id '
        || ' OR '
        || ' e.end_node = r1.element_id '
        || ' ) '
        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        --RAISE NOTICE 'Node % on edge % bound', rec.nid, rec.eid;
        RETURN TRUE; -- one node is start or end
                     -- of a face edge
      END LOOP;

      RETURN FALSE; -- no intersection
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 4 THEN -- point/collection
      RAISE EXCEPTION 'Intersection point/collection not implemented yet';

    ELSE
      RAISE EXCEPTION 'Invalid TopoGeometry type %', tg2.type;
    END IF;

  ELSIF tg1.type = 2 THEN -- [multi]line
    IF tg2.type = 2 THEN -- line/line
  ---------------------------------------------------------
  --
  --  A [multi]line intersects a [multi]line if they share
  --  any Node.
  --
  --
  --
      query =
        'SELECT e1.start_node FROM '
        || quote_ident(toponame) ||
        '.relation r1, '
        || quote_ident(toponame) ||
        '.relation r2, '
        || quote_ident(toponame) ||
        '.edge_data e1, '
        || quote_ident(toponame) ||
        '.edge_data e2 '
        || 'WHERE r1.layer_id = ' || tg1.layer_id
        || ' AND r2.layer_id = ' || tg2.layer_id
        || ' AND r1.topogeo_id = ' || tg1.id
        || ' AND r2.topogeo_id = ' || tg2.id
        || ' AND abs(r1.element_id) = e1.edge_id '
        || ' AND abs(r2.element_id) = e2.edge_id '
        || ' AND ( '
        || ' e1.start_node = e2.start_node '
        || ' OR '
        || ' e1.start_node = e2.end_node '
        || ' OR '
        || ' e1.end_node = e2.start_node '
        || ' OR '
        || ' e1.end_node = e2.end_node '
        || ' )'
        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        RETURN TRUE; -- they share an element
      END LOOP;
      RETURN FALSE; -- no elements shared
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 3 THEN -- line/polygon
  ---------------------------------------------------------
  --
  -- A [multi]line intersects a [multi]polygon if they share
  -- any Node (touch-only case), or if any line edge has any
  -- polygon face on the left or right (full-containment case
  -- + edge crossing case).
  --
  --
      -- E1 are line edges, E2 are polygon edges
      -- R1 are line relations.
      -- R2 are polygon relations.
      -- R2.element_id are FACE ids
      query =
        'SELECT e1.edge_id'
        || ' FROM '
        || quote_ident(toponame) ||
        '.relation r1, '
        || quote_ident(toponame) ||
        '.relation r2, '
        || quote_ident(toponame) ||
        '.edge_data e1, '
        || quote_ident(toponame) ||
        '.edge_data e2 '
        || 'WHERE r1.layer_id = ' || tg1.layer_id
        || ' AND r2.layer_id = ' || tg2.layer_id
        || ' AND r1.topogeo_id = ' || tg1.id
        || ' AND r2.topogeo_id = ' || tg2.id

        -- E1 are line edges
        || ' AND e1.edge_id = abs(r1.element_id) '

        -- E2 are face edges
        || ' AND ( e2.left_face = r2.element_id '
        || '   OR e2.right_face = r2.element_id ) '

        || ' AND ( '

        -- Check if E1 have left-or-right face
        -- being part of R2.element_id
        || ' e1.left_face = r2.element_id '
        || ' OR '
        || ' e1.right_face = r2.element_id '

        -- Check if E1 share start-or-end node
        -- with any E2.
        || ' OR '
        || ' e1.start_node = e2.start_node '
        || ' OR '
        || ' e1.start_node = e2.end_node '
        || ' OR '
        || ' e1.end_node = e2.start_node '
        || ' OR '
        || ' e1.end_node = e2.end_node '

        || ' ) '

        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        RETURN TRUE; -- either common node
                     -- or edge-in-face
      END LOOP;

      RETURN FALSE; -- no intersection
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 4 THEN -- line/collection
      RAISE EXCEPTION 'Intersection line/collection not implemented yet';

    ELSE
      RAISE EXCEPTION 'Invalid TopoGeometry type %', tg2.type;
    END IF;

  ELSIF tg1.type = 3 THEN -- [multi]polygon

    IF tg2.type = 3 THEN -- polygon/polygon
  ---------------------------------------------------------
  --
  -- A [multi]polygon intersects a [multi]polygon if they share
  -- any Node (touch-only case), or if any face edge has any of the
  -- other polygon face on the left or right (full-containment case
  -- + edge crossing case).
  --
  --
      -- E1 are poly1 edges.
      -- E2 are poly2 edges
      -- R1 are poly1 relations.
      -- R2 are poly2 relations.
      -- R1.element_id are poly1 FACE ids
      -- R2.element_id are poly2 FACE ids
      query =
        'SELECT e1.edge_id'
        || ' FROM '
        || quote_ident(toponame) ||
        '.relation r1, '
        || quote_ident(toponame) ||
        '.relation r2, '
        || quote_ident(toponame) ||
        '.edge_data e1, '
        || quote_ident(toponame) ||
        '.edge_data e2 '
        || 'WHERE r1.layer_id = ' || tg1.layer_id
        || ' AND r2.layer_id = ' || tg2.layer_id
        || ' AND r1.topogeo_id = ' || tg1.id
        || ' AND r2.topogeo_id = ' || tg2.id

        -- E1 are poly1 edges
        || ' AND ( e1.left_face = r1.element_id '
        || '   OR e1.right_face = r1.element_id ) '

        -- E2 are poly2 edges
        || ' AND ( e2.left_face = r2.element_id '
        || '   OR e2.right_face = r2.element_id ) '

        || ' AND ( '

        -- Check if any edge from a polygon face
        -- has any of the other polygon face
        -- on the left or right
        || ' e1.left_face = r2.element_id '
        || ' OR '
        || ' e1.right_face = r2.element_id '
        || ' OR '
        || ' e2.left_face = r1.element_id '
        || ' OR '
        || ' e2.right_face = r1.element_id '

        -- Check if E1 share start-or-end node
        -- with any E2.
        || ' OR '
        || ' e1.start_node = e2.start_node '
        || ' OR '
        || ' e1.start_node = e2.end_node '
        || ' OR '
        || ' e1.end_node = e2.start_node '
        || ' OR '
        || ' e1.end_node = e2.end_node '

        || ' ) '

        || ' LIMIT 1';
      --RAISE NOTICE '%', query;
      FOR rec IN EXECUTE query
      LOOP
        RETURN TRUE; -- either common node
                     -- or edge-in-face
      END LOOP;

      RETURN FALSE; -- no intersection
  --
  ---------------------------------------------------------

    ELSIF tg2.type = 4 THEN -- polygon/collection
      RAISE EXCEPTION 'Intersection poly/collection not implemented yet';

    ELSE
      RAISE EXCEPTION 'Invalid TopoGeometry type %', tg2.type;
    END IF;

  ELSIF tg1.type = 4 THEN -- collection
    IF tg2.type = 4 THEN -- collection/collection
      RAISE EXCEPTION 'Intersection collection/collection not implemented yet';
    ELSE
      RAISE EXCEPTION 'Invalid TopoGeometry type %', tg2.type;
    END IF;

  ELSE
    RAISE EXCEPTION 'Invalid TopoGeometry type %', tg1.type;
  END IF;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.layertrigger()
 RETURNS trigger
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  rec RECORD;
  ok BOOL;
  toponame varchar;
  query TEXT;
BEGIN

  --RAISE NOTICE 'LayerTrigger called % % at % level', TG_WHEN, TG_OP, TG_LEVEL;

  IF TG_OP = 'INSERT' THEN
    RAISE EXCEPTION 'LayerTrigger not meant to be called on INSERT';
  ELSIF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'The topology.layer table cannot be updated';
  END IF;

  -- Check for existence of any feature column referencing
  -- this layer
  FOR rec IN SELECT * FROM pg_namespace n, pg_class c, pg_attribute a
    WHERE text(n.nspname) = OLD.schema_name
    AND c.relnamespace = n.oid
    AND text(c.relname) = OLD.table_name
    AND a.attrelid = c.oid
    AND text(a.attname) = OLD.feature_column
  LOOP
    query = 'SELECT * '
         ' FROM ' || quote_ident(OLD.schema_name)
      || '.' || quote_ident(OLD.table_name)
      || ' WHERE layer_id('
      || quote_ident(OLD.feature_column)||') '
         '=' || OLD.layer_id
      || ' LIMIT 1';
    --RAISE NOTICE '%', query;
    FOR rec IN EXECUTE query
    LOOP
      RAISE NOTICE 'A feature referencing layer % of topology % still exists in %.%.%', OLD.layer_id, OLD.topology_id, OLD.schema_name, OLD.table_name, OLD.feature_column;
      RETURN NULL;
    END LOOP;
  END LOOP;

  -- Get topology name
  SELECT name FROM topology.topology INTO toponame
    WHERE id = OLD.topology_id;

  IF toponame IS NULL THEN
    RAISE NOTICE 'Could not find name of topology with id %',
      OLD.layer_id;
  END IF;

  -- Check if any record in the relation table references this layer
  FOR rec IN SELECT c.oid FROM pg_namespace n, pg_class c
    WHERE text(n.nspname) = toponame AND c.relnamespace = n.oid
          AND c.relname = 'relation'
  LOOP
    query = 'SELECT * '
         ' FROM ' || quote_ident(toponame)
      || '.relation '
         ' WHERE layer_id = '|| OLD.layer_id
      || ' LIMIT 1';
    --RAISE NOTICE '%', query;
    FOR rec IN EXECUTE query
    LOOP
      RAISE NOTICE 'A record in %.relation still references layer %', toponame, OLD.layer_id;
      RETURN NULL;
    END LOOP;
  END LOOP;

  RETURN OLD;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.maketopologyprecise(toponame name, bbox geometry DEFAULT NULL::geometry, gridsize double precision DEFAULT NULL::double precision)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  topo topology.topology;
  imprecisePoints GEOMETRY;
  sql TEXT;
  dataBox GEOMETRY;
  dataMagnitude FLOAT8;
  minGridSize FLOAT8;
BEGIN
  topo := findTopology(toponame);
  IF topo.id IS NULL THEN
    RAISE EXCEPTION 'Could not find topology "%"', toponame;
  END IF;

  IF gridSize IS NULL THEN
    gridSize := topo.precision;
  END IF;

  IF gridSize <= 0 THEN
    RAISE NOTICE 'Every vertex is precise with grid size %', gridSize;
    RETURN;
  END IF;

  -- TODO: compute real extent instead of estimated/float4 one?
  -- TODO: generalize a topology.MinTolerance(toponame) ?
  SELECT ST_Union(g) b
  FROM (
    SELECT ST_EstimatedExtent(topo.name, 'edge_data', 'geom')::geometry g
    UNION
    SELECT ST_EstimatedExtent(topo.name, 'node', 'geom')::geometry
  ) foo
  INTO dataBox;

  IF dataBox IS NULL THEN
    RAISE NOTICE 'Every vertex is precise in an empty topology';
    RETURN;
  END IF;

   dataMagnitude = greatest(
      abs(ST_Xmin(dataBox)),
      abs(ST_Xmax(dataBox)),
      abs(ST_Ymin(dataBox)),
      abs(ST_Ymax(dataBox))
  );
  -- TODO: restrict data magnitude computation to requested bbox ?
  minGridSize := topology._st_mintolerance(dataMagnitude);
  IF minGridSize > gridSize THEN
    RAISE EXCEPTION 'Presence of max ordinate value % requires a minimum grid size of %', dataMagnitude, minGridSize;
  END IF;

  -- TODO: recursively grow working bbox to include all edges connected
  --       to all endpoints of edges intersecting it ?

  sql := format(
    $$
UPDATE %1$I.edge_data
SET geom = ST_SnapToGrid(geom, $2)
WHERE ( $1 IS NULL OR geom && $1 )
    $$, topo.name
  );
  EXECUTE sql USING bbox, gridSize;

  sql := format(
    $$
UPDATE %1$I.node
SET geom = ST_SnapToGrid(geom, $2)
WHERE ( $1 IS NULL OR geom && $1 )
    $$, topo.name
  );
  EXECUTE sql USING bbox, gridSize;

  sql := format(
    $$
UPDATE %1$I.face
SET mbr = ST_SnapToGrid(mbr, $2)
WHERE ( $1 IS NULL OR mbr && $1 )
    $$, topo.name
  );
  EXECUTE sql USING bbox, gridSize;

  -- TODO: validate topology if requested ?

END;
$function$
;

CREATE OR REPLACE FUNCTION topology.polygonize(toponame character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  sql text;
  rec RECORD;
  faces int;
BEGIN

  sql := 'SELECT (st_dump(st_polygonize(geom))).geom from '
         || quote_ident(toponame) || '.edge_data';

  faces = 0;
  FOR rec in EXECUTE sql LOOP
    BEGIN
      PERFORM topology.AddFace(toponame, rec.geom);
      faces = faces + 1;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE WARNING 'Error registering face % (%)', rec.geom, SQLERRM;
    END;
  END LOOP;
  RETURN faces || ' faces registered';
END
$function$
;

CREATE OR REPLACE FUNCTION topology.populate_topology_layer()
 RETURNS TABLE(schema_name text, table_name text, feature_column text)
 LANGUAGE sql
AS $function$
  INSERT INTO topology.layer
  WITH checks AS (
  SELECT
    n.nspname sch, r.relname tab,
    replace(c.conname, 'check_topogeom_', '') col,
    --c.consrc src,
    regexp_matches(c.consrc,
      E'\\.topology_id = (\\d+).*\\.layer_id = (\\d+).*\\.type = (\\d+)') inf
  FROM (SELECT conname, connamespace, conrelid, conkey, pg_get_constraintdef(oid) As consrc
		    FROM pg_constraint) AS c, pg_class r, pg_namespace n
  WHERE c.conname LIKE 'check_topogeom_%'
    AND r.oid = c.conrelid
    AND n.oid = r.relnamespace
  ), newrows AS (
    SELECT inf[1]::int as topology_id,
           inf[2]::int as layer_id,
          sch, tab, col, inf[3]::int as feature_type --, src
    FROM checks c
    WHERE NOT EXISTS (
      SELECT * FROM topology.layer l
      WHERE l.schema_name = c.sch
        AND l.table_name = c.tab
        AND l.feature_column = c.col
    )
  )
  SELECT topology_id, layer_id, sch,
         tab, col, feature_type,
         0, NULL
  FROM newrows RETURNING schema_name,table_name,feature_column;
$function$
;

CREATE OR REPLACE FUNCTION topology.postgis_topology_scripts_installed()
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$ SELECT trim('3.6.0'::text || $rev$ 4c1967d $rev$) AS version $function$
;

CREATE OR REPLACE FUNCTION topology.relationtrigger()
 RETURNS trigger
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  toponame varchar;
  topoid integer;
  plyr RECORD; -- parent layer
  rec RECORD;
  ok BOOL;

BEGIN
  IF TG_NARGS != 2 THEN
    RAISE EXCEPTION 'RelationTrigger called with wrong number of arguments';
  END IF;

  topoid = TG_ARGV[0];
  toponame = TG_ARGV[1];

  --RAISE NOTICE 'RelationTrigger called % % on %.relation for a %', TG_WHEN, TG_OP, toponame, TG_LEVEL;

  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'RelationTrigger not meant to be called on DELETE';
  END IF;

  -- Get layer info (and verify it exists)
  ok = false;
  FOR plyr IN EXECUTE 'SELECT * FROM topology.layer '
       'WHERE '
       ' topology_id = ' || topoid
    || ' AND'
       ' layer_id = ' || NEW.layer_id
  LOOP
    ok = true;
    EXIT;
  END LOOP;
  IF NOT ok THEN
    RAISE EXCEPTION 'Layer % does not exist in topology %',
      NEW.layer_id, topoid;
    RETURN NULL;
  END IF;

  IF plyr.level > 0 THEN -- this is hierarchical layer

    -- ElementType must be the layer child id
    IF NEW.element_type != plyr.child_id THEN
      RAISE EXCEPTION 'Type of elements in layer % must be set to its child layer id %', plyr.layer_id, plyr.child_id;
      RETURN NULL;
    END IF;

    -- ElementId must be an existent TopoGeometry in child layer
    ok = false;
    FOR rec IN EXECUTE 'SELECT topogeo_id FROM '
      || quote_ident(toponame) || '.relation '
         ' WHERE layer_id = ' || plyr.child_id
      || ' AND topogeo_id = ' || NEW.element_id
    LOOP
      ok = true;
      EXIT;
    END LOOP;
    IF NOT ok THEN
      RAISE EXCEPTION 'TopoGeometry % does not exist in the child layer %', NEW.element_id, plyr.child_id;
      RETURN NULL;
    END IF;

  ELSE -- this is a basic layer

    -- ElementType must be compatible with layer type
    IF plyr.feature_type != 4
      AND plyr.feature_type != NEW.element_type
    THEN
      RAISE EXCEPTION 'Element of type % is not compatible with layer of type %', NEW.element_type, plyr.feature_type;
      RETURN NULL;
    END IF;

    --
    -- Now lets see if the element is consistent, which
    -- is it exists in the topology tables.
    --

    --
    -- Element is a Node
    --
    IF NEW.element_type = 1
    THEN
      ok = false;
      FOR rec IN EXECUTE 'SELECT node_id FROM '
        || quote_ident(toponame) || '.node '
           ' WHERE node_id = ' || NEW.element_id
      LOOP
        ok = true;
        EXIT;
      END LOOP;
      IF NOT ok THEN
        RAISE EXCEPTION 'Node % does not exist in topology %', NEW.element_id, toponame;
        RETURN NULL;
      END IF;

    --
    -- Element is an Edge
    --
    ELSIF NEW.element_type = 2
    THEN
      ok = false;
      FOR rec IN EXECUTE 'SELECT edge_id FROM '
        || quote_ident(toponame) || '.edge_data '
           ' WHERE edge_id = ' || abs(NEW.element_id)
      LOOP
        ok = true;
        EXIT;
      END LOOP;
      IF NOT ok THEN
        RAISE EXCEPTION 'Edge % does not exist in topology %', NEW.element_id, toponame;
        RETURN NULL;
      END IF;

    --
    -- Element is a Face
    --
    ELSIF NEW.element_type = 3
    THEN
      IF NEW.element_id = 0 THEN
        RAISE EXCEPTION 'Face % cannot be associated with any feature', NEW.element_id;
        RETURN NULL;
      END IF;
      ok = false;
      FOR rec IN EXECUTE 'SELECT face_id FROM '
        || quote_ident(toponame) || '.face '
           ' WHERE face_id = ' || NEW.element_id
      LOOP
        ok = true;
        EXIT;
      END LOOP;
      IF NOT ok THEN
        RAISE EXCEPTION 'Face % does not exist in topology %', NEW.element_id, toponame;
        RETURN NULL;
      END IF;
    END IF;

  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.removeunusedprimitives(atopology text, bbox geometry DEFAULT NULL::geometry)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
  topo topology.topology;
  deletedNodes INT := 0;
  deletedEdges INT := 0;
  deletedNodesDeg2 INT := 0;
  sql TEXT;
  rec RECORD;
  edgeMap JSONB := '{}';
  edge1 BIGINT;
  edge2 BIGINT;
  removedNode BIGINT;
  ok BOOLEAN;
  fixedLinks INT := 0;
  mergedFaces BIGINT[];
  moreMergedFaces BIGINT[];
BEGIN

  topo := findTopology(atopology);
  IF topo.id IS NULL THEN
    RAISE EXCEPTION 'Could not find topology "%"', atopology;
  END IF;

  RAISE NOTICE 'Removing unused edges';

  RAISE DEBUG 'Determining edges not referenced by linear TopoGeoms';
  -- Delete edges not used in non-hierarchical TopoGeometry
  -- from linear typed layers
  sql := format(
    $$
      CREATE TEMPORARY TABLE deleted_edges AS
      SELECT
        edge_id::int8,
        next_right_edge::int8,
        next_left_edge::int8,
        left_face::int8,
        right_face::int8,
        start_node::int8,
        end_node::int8
      FROM %1$I.edge_data e
      WHERE ( $1 IS NULL OR ST_Intersects(geom, $1) )
      AND NOT EXISTS (
        SELECT 1
        FROM %1$I.relation r, topology.layer l
        WHERE r.layer_id = l.layer_id
        AND l.topology_id = $2
        AND l.child_id IS NULL
        AND l.feature_type IN (2, 4)
        AND r.element_id in ( e.edge_id, -e.edge_id )
      )
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql USING bbox, topo.id;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Found % edges not referenced by linear TopoGeoms', fixedLinks;

  -- remove from deleted_edges the edges binding
  -- faces that individually (not both) take part
  -- of the definition of an areal TopoGeometry
  RAISE DEBUG 'Determining edges not binding areal TopoGeoms';
  sql := format(
    $$
      WITH breaking_merges AS (
        SELECT
          DISTINCT
          de.edge_id::int8
          --, ARRAY[r.layer_id, r.topogeo_id] topogeo
          --, array_agg(r.element_id) faces
        FROM
          topology.layer l,
          %1$I.relation r,
          pg_temp.deleted_edges de
        WHERE l.topology_id = %2$L
        AND l.child_id IS NULL -- non-hierarchical layer
        AND l.feature_type IN (3, 4) -- areal or mixed layer
        AND r.layer_id = l.layer_id
        AND r.element_type = 3 -- face primitive
        AND de.left_face != de.right_face -- non-dangling edges
        AND ( r.element_id = de.left_face OR r.element_id = de.right_face )
        GROUP BY de.edge_id, r.layer_id, r.topogeo_id
        HAVING count(DISTINCT r.element_id) != 2
      )
      --SELECT * FROM breaking_merges
      DELETE FROM pg_temp.deleted_edges de
      WHERE edge_id IN (
        SELECT edge_id FROM breaking_merges
      )
    $$,
    topo.name,
    topo.id
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Retained % edges binding areal TopoGeoms', fixedLinks;
  --FOR rec IN EXECUTE sql LOOP
    --RAISE NOTICE 'Should retain edges % binding areal TopoGeom % in layer %', rec.edge_id, rec.topogeo_id, rec.layer_id;
  --END LOOP;


  RAISE DEBUG 'Deleting unused edges';
  sql := format(
    $$
      DELETE FROM %1$I.edge_data e
      WHERE e.edge_id IN (
        SELECT edge_id FROM pg_temp.deleted_edges
      )
    $$,
    topo.name
  );
  EXECUTE sql;
  GET DIAGNOSTICS deletedEdges = ROW_COUNT;
  RAISE DEBUG 'Deleted % unused edges', deletedEdges;


  RAISE DEBUG 'Fixing broken next_right_edge links';
  sql := format(
    $$
      UPDATE %1$I.edge_data e
      SET
        next_right_edge =
          CASE
          WHEN e.next_right_edge = ne.edge_id THEN
            ne.next_right_edge
          ELSE
            ne.next_left_edge
          END,
        abs_next_right_edge =
          CASE
          WHEN e.next_right_edge = ne.edge_id THEN
            abs(ne.next_right_edge)
          ELSE
            abs(ne.next_left_edge)
          END
      FROM pg_temp.deleted_edges ne
      WHERE e.abs_next_right_edge = ne.edge_id
        AND e.next_right_edge !=
        CASE
        WHEN e.next_right_edge = ne.edge_id THEN
          ne.next_right_edge
        ELSE
          ne.next_left_edge
        END
      RETURNING e.*
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  LOOP
    EXECUTE sql;
    GET DIAGNOSTICS fixedLinks = ROW_COUNT;
--    fixedLinks := 0;
--    FOR rec IN EXECUTE sql LOOP
--      fixedLinks := fixedLinks + 1;
--      RAISE DEBUG 'Updated next_right_edge link for edge %, now having next_right_edge=% and abs_next_right_edge=%', rec.edge_id, rec.next_right_edge, rec.abs_next_right_edge;
--    END LOOP;
    IF fixedLinks = 0 THEN
      RAISE DEBUG 'No (more) broken next_right_edge links';
      EXIT;
    END IF;
    RAISE DEBUG 'Updated % broken next_right_edge links', fixedLinks;
  END LOOP;

  RAISE DEBUG 'Fixing broken next_left_edge links';
  sql := format(
    $$
      UPDATE %1$I.edge_data e
      SET
        next_left_edge =
          CASE
          WHEN e.next_left_edge = ne.edge_id THEN
            ne.next_right_edge
          ELSE
            ne.next_left_edge
          END,
        abs_next_left_edge =
          CASE
          WHEN e.next_left_edge = ne.edge_id THEN
            abs(ne.next_right_edge)
          ELSE
            abs(ne.next_left_edge)
          END
      FROM pg_temp.deleted_edges ne
      WHERE e.abs_next_left_edge = ne.edge_id
        -- Avoid updating records which do not need
        -- to be updated (alternatively we could DELETE
        -- those records from deleted_edges before next iteration)
        AND e.next_left_edge !=
        CASE
        WHEN e.next_left_edge = ne.edge_id THEN
          ne.next_right_edge
        ELSE
          ne.next_left_edge
        END
      RETURNING e.*
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  LOOP
    EXECUTE sql;
    GET DIAGNOSTICS fixedLinks = ROW_COUNT;
--    fixedLinks := 0;
--    FOR rec IN EXECUTE sql LOOP
--      fixedLinks := fixedLinks + 1;
--      RAISE DEBUG 'Updated next_left_edge link for edge %, now having next_left_edge=% and abs_next_left_edge=%', rec.edge_id, rec.next_left_edge, rec.abs_next_left_edge;
--    END LOOP;
    IF fixedLinks = 0 THEN
      RAISE DEBUG 'No (more) broken next_left_edge links found';
      EXIT;
    END IF;
    RAISE DEBUG 'Updated % broken next_left_edge links', fixedLinks;
  END LOOP;

  --
  -- Build arrays of faces to be merged
  --

  RAISE DEBUG 'Building face merge sets';

  CREATE TEMPORARY TABLE mergeable_faces AS
  WITH merges AS (
    SELECT
      DISTINCT
      ARRAY[
        LEAST(left_face, right_face),
        GREATEST(left_face, right_face)
      ]::int8[] faceset
    FROM deleted_edges
    WHERE left_face != right_face
  )
  SELECT faceset
  FROM merges;

  CREATE TEMPORARY TABLE merged_faces (keep BIGINT, merge BIGINT[]);

  LOOP -- {

    -- Fetch next merge
    DELETE FROM mergeable_faces
    WHERE ctid = (SELECT ctid FROM mergeable_faces LIMIT 1)
    RETURNING faceset
    INTO mergedFaces;
    IF mergedFaces IS NULL THEN
      EXIT;
    END IF;

    RAISE DEBUG 'Next merged faces start with: %', mergedFaces;

    LOOP --{
      WITH deleted AS (
        DELETE FROM mergeable_faces
        WHERE faceset && mergedFaces
        RETURNING faceset
      ), flood_faces AS (
        SELECT DISTINCT unnest(faceset) merged
        FROM deleted
      )
      SELECT array_agg(merged)
      FROM flood_faces
      INTO moreMergedFaces;

      IF moreMergedFaces IS NULL THEN
        EXIT;
      END IF;

      RAISE DEBUG 'There is more merged faces: %', moreMergedFaces;
      SELECT array_agg(x) FROM (
        SELECT unnest(mergedFaces) x
          UNION
        SELECT unnest(moreMergedFaces)
      ) foo
      INTO mergedFaces;
      RAISE DEBUG 'Merged faces grows to: %', mergedFaces;

    END LOOP; --}

    mergedFaces := array_agg(distinct x ORDER BY x) FROM unnest(mergedFaces) x;
    RAISE DEBUG 'Storing merged faceset: %', mergedFaces;

    INSERT INTO pg_temp.merged_faces VALUES (
      mergedFaces[1],
      array_remove(mergedFaces, mergedFaces[1])
    );

  END LOOP; --}

  DROP TABLE pg_temp.mergeable_faces;

  --
  -- Fix face labels
  --

  RAISE DEBUG 'Fixing broken left_face labels';
  sql := format(
    $$
      UPDATE %1$I.edge_data e
      SET left_face = mf.keep
      FROM pg_temp.merged_faces mf
      WHERE e.left_face != mf.keep
        AND e.left_face = ANY(mf.merge)
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Updated % broken left_face links', fixedLinks;

  RAISE DEBUG 'Fixing broken right_face labels';
  sql := format(
    $$
      UPDATE %1$I.edge_data e
      SET right_face = mf.keep
      FROM pg_temp.merged_faces mf
      WHERE e.right_face != mf.keep
        AND e.right_face = ANY(mf.merge)
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Updated % broken right_face links', fixedLinks;


  RAISE DEBUG 'Updating containing_face labels for merged faces';
  sql := format(
    $$
      UPDATE %1$I.node n
      SET containing_face = mf.keep
      FROM pg_temp.merged_faces mf
      WHERE n.containing_face != mf.keep
      AND n.containing_face = ANY(mf.merge)
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Updated % containing_face labels for nodes', fixedLinks;

  --
  -- Fix face table (delete/update mbr)
  --

  RAISE DEBUG 'Updating merged faces MBR';
  sql := format(
    $$
      WITH merged_mbr AS (
        SELECT
          mf.keep,
          ST_Envelope(
            ST_Collect(
              f.mbr
            )
          ) mbr
        FROM pg_temp.merged_faces mf
        JOIN %1$I.face f ON (
          f.face_id = mf.keep OR
          f.face_id = ANY( mf.merge )
        )
        WHERE mf.keep != 0
        GROUP by mf.keep
      )
      UPDATE %1$I.face f
      SET mbr = m.mbr
      FROM merged_mbr m
      WHERE f.face_id = m.keep
    $$,
    topo.name
  );
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Updated % merged faces MBR', fixedLinks;

  RAISE DEBUG 'Deleting removed faces';
  sql := format(
    $$
      DELETE FROM %1$I.face
      USING pg_temp.merged_faces mf
      WHERE face_id = ANY (mf.merge)
    $$,
    topo.name
  );
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Deleted % merged faces', fixedLinks;

  --
  -- Fix TopoGeometry
  --

  RAISE DEBUG 'Updating areal TopoGeometry definitions';
  -- We remove the merged faces from the definition
  -- of areal TopoGeometry objects
  sql := format(
    $$
      WITH deleted AS (
        DELETE FROM %1$I.relation r
        USING topology.layer l, pg_temp.merged_faces mf
        WHERE l.topology_id = %2$L
        AND l.feature_type IN (3, 4)
        AND l.child_id IS NULL
        AND r.layer_id = l.layer_id
        AND r.element_id = ANY (mf.merge)
        RETURNING
          r.topogeo_id,
          r.layer_id,
          l.schema_name,
          l.table_name,
          l.feature_column,
          mf.merge,
          mf.keep,
          r.element_id
      )
      SELECT
        topogeo_id,
        layer_id,
        schema_name,
        table_name,
        feature_column,
        merge,
        keep,
        array_agg(element_id) lost_faces
      FROM deleted
      GROUP BY 1,2,3,4,5,6,7
    $$,
    topo.name,
    topo.id
  );
  --RAISE NOTICE 'SQL: %', sql;
  FOR rec IN EXECUTE sql
  LOOP
    RAISE DEBUG 'Areal TopoGeometry % in layer %.%.% '
      'lost faces % (kept %) in its composition',
      rec.topogeo_id, rec.schema_name,
      rec.table_name, rec.feature_column,
      rec.lost_faces, rec.keep
    ;
  END LOOP;

  --
  -- Mark newly isolated nodes as such
  --

  RAISE DEBUG 'Determining newly isolated nodes';
  sql := format(
    $$
      WITH unlinked_nodes AS (
        SELECT start_node node_id FROM pg_temp.deleted_edges
          UNION
        SELECT end_node FROM pg_temp.deleted_edges
      ), isolated AS (
        SELECT node_id FROM unlinked_nodes
        EXCEPT SELECT start_node FROM %1$I.edge_data
        EXCEPT  SELECT end_node FROM %1$I.edge_data
      ), incident_faces AS (
        SELECT
          node_id,
          array_agg(DISTINCT face_id) incident_faces
        FROM (
          SELECT DISTINCT node_id, unnest(face_id) face_id
          FROM (
            SELECT
              i.node_id,
              ARRAY[e.left_face, e.right_face] face_id
            FROM isolated i, deleted_edges e
            WHERE e.start_node = i.node_id
              UNION
            SELECT
              i.node_id,
              ARRAY[e.left_face, e.right_face] face_id
            FROM isolated i, deleted_edges e
            WHERE e.end_node = i.node_id
          ) foo
        ) bar
        GROUP BY node_id
      ), containing_faces AS (
        SELECT
          inc.node_id,
          COALESCE(mf.keep, incident_faces[1]) face_id
        FROM incident_faces inc
        LEFT JOIN pg_temp.merged_faces mf
          ON ( inc.incident_faces && mf.merge )
      )
      UPDATE %1$I.node n
      SET containing_face = cf.face_id
      FROM containing_faces cf
      WHERE n.node_id = cf.node_id
      AND n.containing_face IS DISTINCT FROM cf.face_id
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  EXECUTE sql;
  GET DIAGNOSTICS fixedLinks = ROW_COUNT;
  RAISE DEBUG 'Isolated % nodes', fixedLinks;

  RAISE NOTICE 'Removed % unused edges', deletedEdges;


  --
  -- Clean isolated nodes
  --

  -- Cleanup isolated nodes
  -- (non-isolated ones would have become isolated by now)
  sql := format(
    $$
      SELECT
        n.node_id
      FROM
        %1$I.node n
      WHERE ( $1 IS NULL OR ST_Intersects(n.geom, $1) )
      AND n.containing_face IS NOT NULL
      AND NOT EXISTS (
        SELECT 1
        FROM %1$I.relation r, topology.layer l
        WHERE r.layer_id = l.layer_id
        AND l.topology_id = $2
        AND l.child_id IS NULL
        AND l.feature_type = 1
        AND r.element_id = n.node_id
      )
    $$,
    topo.name
  );
  RAISE NOTICE 'Removing isolated nodes';
  FOR rec in EXECUTE sql USING bbox, topo.id
  LOOP --{
    BEGIN
      PERFORM topology.ST_RemIsoNode(topo.name, rec.node_id);
      RAISE DEBUG 'Removed isolated node %', rec.node_id;
      deletedNodes := deletedNodes + 1;
    EXCEPTION WHEN OTHERS
    THEN
      RAISE WARNING 'Isolated node % could not be removed: %', rec.node_id, SQLERRM;
    END;
  END LOOP; --}
  RAISE NOTICE 'Removed % isolated nodes', deletedNodes;

  -- Remove nodes connecting only 2 edges if
  -- no lineal TopoGeometry exists that is defined
  -- by only one of them
  sql := format(
    $$
      WITH
      unused_connected_nodes_in_bbox AS (
        SELECT
          n.node_id
        FROM %1$I.node n
        WHERE
          ( $1 IS NULL OR ST_Intersects(n.geom, $1) )
          AND n.containing_face IS NULL

          EXCEPT

        SELECT r.element_id
        FROM %1$I.relation r
        JOIN topology.layer l ON ( r.layer_id = l.layer_id )
        WHERE l.child_id IS NULL
        AND l.topology_id = $2
        AND l.feature_type IN ( 1, 4 ) -- puntual or mixed layer
        AND r.element_type = 1 -- node primitive
      ),
      removable_nodes_of_degree_2_in_bbox AS (
        SELECT
          n.node_id,
          array_agg(
            e.edge_id
            -- order to make cleanup outcome predictable
            ORDER BY e.edge_id
          ) edges
        FROM
          unused_connected_nodes_in_bbox n,
          %1$I.edge e
        WHERE (
            n.node_id = e.start_node
            OR n.node_id = e.end_node
          )
        GROUP BY n.node_id
        HAVING count(e.edge_id) = 2
        -- Do not consider nodes used by closed edges as removable
        AND NOT 't' = ANY( array_agg(e.start_node = e.end_node) )
      ),
      breaking_heals AS (
        SELECT
          DISTINCT
          n.node_id
          -- , ARRAY[r.layer_id, r.topogeo_id]
          -- , array_agg(r.element_id) edges
        FROM
          removable_nodes_of_degree_2_in_bbox n,
          %1$I.relation r,
          topology.layer l
        WHERE l.topology_id = $2
          AND l.child_id IS NULL
          AND l.feature_type IN ( 2, 4 ) -- lineal or mixed layer
          AND r.layer_id = l.layer_id
          AND r.element_type = 2 -- edge primitive
          AND r.element_id IN (
            n.edges[1], -n.edges[1],
            n.edges[2], -n.edges[2]
          )
          GROUP BY n.node_id, r.layer_id, r.topogeo_id
          HAVING count(DISTINCT abs(r.element_id)) != 2
      ),
      valid_heals AS (
        SELECT
          node_id,
          edges
        FROM removable_nodes_of_degree_2_in_bbox
        WHERE node_id NOT IN (
          SELECT node_id FROM breaking_heals
        )
      )
      SELECT
        array_agg(node_id) connecting_nodes,
        edges[1] edge1,
        edges[2] edge2
      FROM valid_heals
      GROUP BY edges
    $$,
    topo.name
  );
  --RAISE DEBUG 'SQL: %', sql;
  RAISE NOTICE 'Removing unneeded nodes of degree 2';
  EXECUTE sql USING bbox, topo.id;
  FOR rec in EXECUTE sql USING bbox, topo.id
  LOOP --{
    RAISE DEBUG 'edgeMap: %', edgeMap;
    -- Edges may have changed name
    edge1 := COALESCE( (edgeMap -> rec.edge1::text)::int, rec.edge1);
    edge2 := COALESCE( (edgeMap -> rec.edge2::text)::int, rec.edge2);

    RAISE DEBUG 'Should heal edges % (now %) and % (now %) bound by nodes %',
      rec.edge1, edge1, rec.edge2, edge2, rec.connecting_nodes;

    IF edge1 = edge2 THEN
      -- Nothing to merge here, continue
      CONTINUE;
    END IF;
    ok := false;

    BEGIN
      -- TODO: replace ST_ModEdgeHeal loop with a faster direct deletion and healing
      removedNode := topology.ST_ModEdgeHeal(topo.name, edge1, edge2);
      IF NOT removedNode = ANY ( rec.connecting_nodes ) THEN
        RAISE EXCEPTION 'Healing of edges % and % was reported '
                        'to remove node % while we expected any of % instead',
                        edge1, edge2, removedNode, rec.connecting_nodes;
      END IF;
      RAISE DEBUG 'Edge % merged into %, dropping node %', edge2, edge1, removedNode;
      ok := 1;
    EXCEPTION WHEN OTHERS
    THEN
      RAISE WARNING 'Edges % and % joined by node % could not be healed: %', edge1, edge2, rec.connecting_nodes, SQLERRM;
    END;
    IF ok THEN
      -- edge2 was now renamed to edge1, update map
      edgeMap := jsonb_set(edgeMap, ARRAY[edge2::text], to_jsonb(edge1));
      deletedNodesDeg2 := deletedNodesDeg2 + 1;
    END IF;
  END LOOP; --}
  RAISE NOTICE 'Removed % unneeded nodes of degree 2', deletedNodesDeg2;

  DROP TABLE pg_temp.deleted_edges;
  DROP TABLE pg_temp.merged_faces;

  RETURN deletedEdges + deletedNodes + deletedNodesDeg2;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.renametopogeometrycolumn(layer_table regclass, feature_column name, new_name name)
 RETURNS layer
 LANGUAGE plpgsql
AS $function$
DECLARE
  layer topology.layer;
  sql text;
BEGIN

  layer := topology.FindLayer(layer_table, feature_column);
  IF layer IS NULL THEN
    RAISE EXCEPTION 'Layer %.% does not exist', layer_table, feature_column;
  END IF;

  --
  -- Rename TopoGeometry column
  --
  sql := format('ALTER TABLE %s RENAME %I to %I',
    layer_table, feature_column, new_name);
  EXECUTE sql;

  -- Update topology.layer record

  -- Temporarily disable integrity check
  ALTER TABLE topology.layer DISABLE TRIGGER layer_integrity_checks;

  sql := format(
      'UPDATE topology.layer SET feature_column = %L '
      'WHERE topology_id = $1 and layer_id = $2',
      new_name
  );
  EXECUTE sql USING layer.topology_id, layer.layer_id;

  -- Re-enable integrity check
  -- TODO: tweak layer_integrity_checks to allow this
  ALTER TABLE topology.layer ENABLE TRIGGER layer_integrity_checks;

  --
  -- Rename constraints on TopoGeom column
  --
  sql := format(
    'ALTER TABLE %s RENAME CONSTRAINT '
    '"check_topogeom_%s" TO "check_topogeom_%s"',
    layer_table, feature_column, new_name
  );
  EXECUTE sql;

  layer.feature_column = new_name;
  RETURN layer;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.renametopology(old_name character varying, new_name character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  sql text;
BEGIN

  sql := format(
    'ALTER SCHEMA %I RENAME TO %I',
    old_name, new_name
  );
  EXECUTE sql;

  sql := format(
    'UPDATE topology.topology SET name = %L WHERE name = %L',
    new_name, old_name
  );
  EXECUTE sql;

  RETURN new_name;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.st_addedgemodface(atopology character varying, anode bigint, anothernode bigint, acurve geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_AddEdgeModFace$function$
;

CREATE OR REPLACE FUNCTION topology.st_addedgenewfaces(atopology character varying, anode bigint, anothernode bigint, acurve geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_AddEdgeNewFaces$function$
;

CREATE OR REPLACE FUNCTION topology.st_addisoedge(atopology character varying, anode bigint, anothernode bigint, acurve geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_AddIsoEdge$function$
;

CREATE OR REPLACE FUNCTION topology.st_addisonode(atopology character varying, aface bigint, apoint geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_AddIsoNode$function$
;

CREATE OR REPLACE FUNCTION topology.st_changeedgegeom(atopology character varying, anedge bigint, acurve geometry)
 RETURNS text
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_ChangeEdgeGeom$function$
;

CREATE OR REPLACE FUNCTION topology.st_createtopogeo(atopology character varying, acollection geometry)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  rec RECORD;
  points GEOMETRY;
  nodededges GEOMETRY;
  topoinfo RECORD;
BEGIN

  IF atopology IS NULL OR acollection IS NULL THEN
    RAISE EXCEPTION 'SQL/MM Spatial exception - null argument';
  END IF;

  -- Get topology information
  BEGIN
    SELECT * FROM topology.topology
      INTO STRICT topoinfo WHERE name = atopology;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'SQL/MM Spatial exception - invalid topology name';
  END;

  -- Check SRID compatibility
  IF ST_SRID(acollection) != topoinfo.SRID THEN
    RAISE EXCEPTION 'Geometry SRID (%) does not match topology SRID (%)',
      ST_SRID(acollection), topoinfo.SRID;
  END IF;

  -- Verify pre-conditions (valid, empty topology schema exists)
  BEGIN -- {

    -- Verify the topology views in the topology schema to be empty
    FOR rec in EXECUTE
      'SELECT count(*) FROM '
      || quote_ident(atopology) || '.edge_data '
      || ' UNION ' ||
      'SELECT count(*) FROM '
      || quote_ident(atopology) || '.node '
    LOOP
      IF rec.count > 0 THEN
    RAISE EXCEPTION 'SQL/MM Spatial exception - non-empty view';
      END IF;
    END LOOP;

    -- face check is separated as it will contain a single (world)
    -- face record
    FOR rec in EXECUTE
      'SELECT count(*) FROM '
      || quote_ident(atopology) || '.face '
    LOOP
      IF rec.count != 1 THEN
    RAISE EXCEPTION 'SQL/MM Spatial exception - non-empty face view';
      END IF;
    END LOOP;

  EXCEPTION
    WHEN INVALID_SCHEMA_NAME THEN
      RAISE EXCEPTION 'SQL/MM Spatial exception - invalid topology name';
    WHEN UNDEFINED_TABLE THEN
      RAISE EXCEPTION 'SQL/MM Spatial exception - non-existent view';

  END; -- }


  --
  -- Node input linework with itself
  --
  WITH components AS ( SELECT geom FROM ST_Dump(acollection) )
  SELECT ST_UnaryUnion(ST_Collect(geom)) FROM (
    SELECT geom FROM components
    WHERE ST_Dimension(geom) = 1
      UNION ALL
    SELECT ST_Boundary(geom) FROM components
    WHERE ST_Dimension(geom) = 2
  ) as linework INTO STRICT nodededges;


  --
  -- Linemerge the resulting edges, to reduce the working set
  -- NOTE: this is more of a workaround for GEOS splitting overlapping
  --       lines to each of the segments.
  --
  SELECT ST_LineMerge(nodededges) INTO STRICT nodededges;


  --
  -- Collect input points and input lines endpoints
  --
  WITH components AS ( SELECT geom FROM ST_Dump(acollection) )
  SELECT ST_Union(geom) FROM (
    SELECT geom FROM components
      WHERE ST_Dimension(geom) = 0
    UNION ALL
    SELECT ST_Boundary(geom) FROM components
      WHERE ST_Dimension(geom) = 1
  ) as nodes INTO STRICT points;


  --
  -- Further split edges by points, if needed
  --
  IF points IS NOT NULL THEN
    nodededges := ST_Split(nodededges, points);
  END IF; -- points is not null


  --
  -- Add pivot face (-1 id)
  --
  EXECUTE format('INSERT INTO %I.face(face_id) VALUES (-1)', atopology);

  --
  -- Collect possibly isolated points, to add later
  --
  WITH components AS ( SELECT geom FROM ST_Dump(acollection) )
  SELECT ST_Union(geom) FROM components
  WHERE ST_Dimension(geom) = 0
  INTO STRICT points;

  --
  -- Add all linework
  -- NOTE: we do this in an ordered way to be predictable
  --
  FOR rec IN
    WITH linework AS ( SELECT geom FROM ST_Dump(nodededges) )
    SELECT topology._TopoGeo_addLinestringNoFace(atopology, geom)
    FROM linework
    ORDER BY geom
  LOOP
  END LOOP;

  --
  -- Register all faces
  --
  PERFORM topology._RegisterMissingFaces(atopology);


  --
  -- Delete pivot face (-1 id)
  --
  EXECUTE format('DELETE FROM %I.face WHERE face_id = -1', atopology);

  --
  -- Add collected points so isolated ones get correctly
  -- marked as being in their face
  -- NOTE: we do this in an ordered way to be predictable
  --
  FOR rec IN SELECT geom FROM
    ( SELECT * FROM ST_Dump(points) ) foo
    ORDER BY geom
  LOOP
    PERFORM topology.TopoGeo_addPoint(atopology, rec.geom);
  END LOOP;

  RETURN 'Topology ' || atopology || ' populated';

END
$function$
;

CREATE OR REPLACE FUNCTION topology.st_geometrytype(tg topogeometry)
 RETURNS text
 LANGUAGE sql
 STABLE STRICT
AS $function$
	SELECT CASE
		WHEN type($1) = 1 THEN 'ST_MultiPoint'
		WHEN type($1) = 2 THEN 'ST_MultiLinestring'
		WHEN type($1) = 3 THEN 'ST_MultiPolygon'
		WHEN type($1) = 4 THEN 'ST_GeometryCollection'
		ELSE 'ST_Unexpected'
		END;
$function$
;

CREATE OR REPLACE FUNCTION topology.st_getfaceedges(toponame character varying, face_id bigint)
 RETURNS SETOF getfaceedges_returntype
 LANGUAGE c
 STABLE
AS '$libdir/postgis_topology-3', $function$ST_GetFaceEdges$function$
;

CREATE OR REPLACE FUNCTION topology.st_getfacegeometry(toponame character varying, aface bigint)
 RETURNS geometry
 LANGUAGE c
 STABLE
AS '$libdir/postgis_topology-3', $function$ST_GetFaceGeometry$function$
;

CREATE OR REPLACE FUNCTION topology.st_inittopogeo(atopology character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  rec RECORD;
  topology_id numeric;
BEGIN
  IF atopology IS NULL THEN
    RAISE EXCEPTION 'SQL/MM Spatial exception - null argument';
  END IF;

  FOR rec IN SELECT * FROM pg_namespace WHERE text(nspname) = atopology
  LOOP
    RAISE EXCEPTION 'SQL/MM Spatial exception - schema already exists';
  END LOOP;

  FOR rec IN EXECUTE 'SELECT topology.CreateTopology('
    ||quote_literal(atopology)|| ') as id'
  LOOP
    topology_id := rec.id;
  END LOOP;

  RETURN 'Topology-Geometry ' || quote_literal(atopology)
    || ' (id:' || topology_id || ') created.';
END
$function$
;

CREATE OR REPLACE FUNCTION topology.st_modedgeheal(toponame character varying, e1id bigint, e2id bigint)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_ModEdgeHeal$function$
;

CREATE OR REPLACE FUNCTION topology.st_modedgesplit(atopology character varying, anedge bigint, apoint geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_ModEdgeSplit$function$
;

CREATE OR REPLACE FUNCTION topology.st_moveisonode(atopology character varying, anode bigint, apoint geometry)
 RETURNS text
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_MoveIsoNode$function$
;

CREATE OR REPLACE FUNCTION topology.st_newedgeheal(toponame character varying, e1id bigint, e2id bigint)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_NewEdgeHeal$function$
;

CREATE OR REPLACE FUNCTION topology.st_newedgessplit(atopology character varying, anedge bigint, apoint geometry)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_NewEdgesSplit$function$
;

CREATE OR REPLACE FUNCTION topology.st_remedgemodface(toponame character varying, e1id bigint)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_RemEdgeModFace$function$
;

CREATE OR REPLACE FUNCTION topology.st_remedgenewface(toponame character varying, e1id bigint)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_RemEdgeNewFace$function$
;

CREATE OR REPLACE FUNCTION topology.st_remisonode(character varying, bigint)
 RETURNS text
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_RemoveIsoNode$function$
;

CREATE OR REPLACE FUNCTION topology.st_removeisoedge(atopology character varying, anedge bigint)
 RETURNS text
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_RemIsoEdge$function$
;

CREATE OR REPLACE FUNCTION topology.st_removeisonode(atopology character varying, anode bigint)
 RETURNS text
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$ST_RemoveIsoNode$function$
;

CREATE OR REPLACE FUNCTION topology.st_simplify(tg topogeometry, tolerance double precision)
 RETURNS geometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  topology_info RECORD;
  layer_info RECORD;
  child_layer_info RECORD;
  geom geometry;
  sql TEXT;
BEGIN

  -- Get topology information
  SELECT id, name FROM topology.topology
    INTO topology_info
    WHERE id = tg.topology_id;
  IF NOT FOUND THEN
      RAISE EXCEPTION 'No topology with id "%" in topology.topology', tg.topology_id;
  END IF;

  -- Get layer info
  SELECT * FROM topology.layer
    WHERE topology_id = tg.topology_id
    AND layer_id = tg.layer_id
    INTO layer_info;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Could not find TopoGeometry layer % in topology %', tg.layer_id, tg.topology_id;
  END IF;

  --
  -- If this feature layer is on any level > 0 we will
  -- compute the topological union of all simplified child
  -- features in fact recursing.
  --
  IF layer_info.level > 0 THEN -- {

    -- Get child layer info
    SELECT * FROM topology.layer WHERE layer_id = layer_info.child_id
      AND topology_id = tg.topology_id
      INTO child_layer_info;
    IF NOT FOUND THEN
      RAISE EXCEPTION 'Invalid layer % in topology % (unexistent child layer %)', tg.layer_id, tg.topology_id, layer_info.child_id;
    END IF;

    sql := 'SELECT st_multi(st_union(topology.ST_Simplify('
      || quote_ident(child_layer_info.feature_column)
      || ',' || tolerance || '))) as geom FROM '
      || quote_ident(child_layer_info.schema_name) || '.'
      || quote_ident(child_layer_info.table_name)
      || ', ' || quote_ident(topology_info.name) || '.relation pr'
      || ' WHERE '
      || ' pr.topogeo_id = ' || tg.id
      || ' AND '
      || ' pr.layer_id = ' || tg.layer_id
      || ' AND '
      || ' id('||quote_ident(child_layer_info.feature_column)
      || ') = pr.element_id '
      || ' AND '
      || 'layer_id('||quote_ident(child_layer_info.feature_column)
      || ') = pr.element_type ';
    RAISE DEBUG '%', sql;
    EXECUTE sql INTO geom;

  ELSIF tg.type = 3 THEN -- [multi]polygon -- }{

    -- TODO: use ST_GetFaceEdges
    -- TODO: is st_unaryunion needed?
    sql := 'SELECT st_multi(st_unaryunion(ST_BuildArea(ST_Node(ST_Collect(ST_Simplify(geom, '
      || tolerance || ')))))) as geom FROM '
      || quote_ident(topology_info.name)
      || '.edge_data e, '
      || quote_ident(topology_info.name)
      || '.relation r WHERE ( e.left_face = r.element_id'
      || ' OR e.right_face = r.element_id )'
      || ' AND r.topogeo_id = ' || tg.id
      || ' AND r.layer_id = ' || tg.layer_id
      || ' AND element_type = 3 ';
    RAISE DEBUG '%', sql;
    EXECUTE sql INTO geom;

  ELSIF tg.type = 2 THEN -- [multi]line -- }{

    sql :=
      'SELECT st_multi(ST_LineMerge(ST_Node(ST_Collect(ST_Simplify(e.geom,'
      || tolerance || '))))) as g FROM '
      || quote_ident(topology_info.name) || '.edge e, '
      || quote_ident(topology_info.name) || '.relation r '
      || ' WHERE r.topogeo_id = ' || tg.id
      || ' AND r.layer_id = ' || tg.layer_id
      || ' AND r.element_type = 2 '
      || ' AND abs(r.element_id) = e.edge_id';
    EXECUTE sql INTO geom;

  ELSIF tg.type = 1 THEN -- [multi]point -- }{

    -- Can't simplify points...
    geom := topology.Geometry(tg);

  ELSIF tg.type = 4 THEN -- mixed collection -- }{

   sql := 'WITH areas AS ( '
      || 'SELECT st_multi(st_union(ST_BuildArea(ST_Node(ST_Collect(ST_Simplify(geom, '
      || tolerance || ')))) as geom FROM '
      || quote_ident(topology_info.name)
      || '.edge_data e, '
      || quote_ident(topology_info.name)
      || '.relation r WHERE ( e.left_face = r.element_id'
      || ' OR e.right_face = r.element_id )'
      || ' AND r.topogeo_id = ' || tg.id
      || ' AND r.layer_id = ' || tg.layer_id
      || ' AND element_type = 3 ), '
      || 'lines AS ( '
      || 'SELECT st_multi(ST_LineMerge(ST_Collect(ST_Simplify(e.geom,'
      || tolerance || ')))) as g FROM '
      || quote_ident(topology_info.name) || '.edge e, '
      || quote_ident(topology_info.name) || '.relation r '
      || ' WHERE r.topogeo_id = ' || tg.id
      || ' AND r.layer_id = ' || tg.layer_id
      || ' AND r.element_type = 2 '
      || ' AND abs(r.element_id) = e.edge_id ), '
      || ' points as ( SELECT st_union(n.geom) as g FROM '
      || quote_ident(topology_info.name) || '.node n, '
      || quote_ident(topology_info.name) || '.relation r '
      || ' WHERE r.topogeo_id = ' || tg.id
      || ' AND r.layer_id = ' || tg.layer_id
      || ' AND r.element_type = 1 '
      || ' AND r.element_id = n.node_id ), '
      || ' un as ( SELECT g FROM areas UNION ALL SELECT g FROM lines '
      || '          UNION ALL SELECT g FROM points ) '
      || 'SELECT ST_Multi(ST_Collect(g)) FROM un';
    EXECUTE sql INTO geom;

  ELSE -- }{

    RAISE EXCEPTION 'Invalid TopoGeometries (unknown type %)', tg.type;

  END IF; -- }

  RETURN geom;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.st_srid(tg topogeometry)
 RETURNS integer
 LANGUAGE sql
 STRICT
AS $function$
	SELECT srid FROM topology.topology
  WHERE id = topology_id(tg);
$function$
;

CREATE OR REPLACE FUNCTION topology.topoelement(topo topogeometry)
 RETURNS topoelement
 LANGUAGE sql
 IMMUTABLE PARALLEL SAFE COST 1
AS $function$SELECT ARRAY[topo.id::bigint,topo.layer_id::bigint]::topology.topoelement;$function$
;

CREATE OR REPLACE FUNCTION topology.topoelementarray_append(topoelementarray, topoelement)
 RETURNS topoelementarray
 LANGUAGE sql
 IMMUTABLE
AS $function$
	SELECT CASE
		WHEN $1 IS NULL THEN
			topology.TopoElementArray('{' || $2::text || '}')
		ELSE
			topology.TopoElementArray($1::bigint[][]||$2::bigint[])
		END;
$function$
;

CREATE OR REPLACE FUNCTION topology.topogeo_addgeometry(atopology character varying, ageom geometry, tolerance double precision DEFAULT 0)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
BEGIN
	RAISE EXCEPTION 'TopoGeo_AddGeometry not implemented yet, use TopoGeo_LoadGeometry';
END
$function$
;

CREATE OR REPLACE FUNCTION topology.topogeo_addlinestring(atopology character varying, aline geometry, tolerance double precision DEFAULT 0)
 RETURNS SETOF bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$TopoGeo_AddLinestring$function$
;

CREATE OR REPLACE FUNCTION topology.topogeo_addpoint(atopology character varying, apoint geometry, tolerance double precision DEFAULT 0)
 RETURNS bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$TopoGeo_AddPoint$function$
;

CREATE OR REPLACE FUNCTION topology.topogeo_addpolygon(atopology character varying, apoly geometry, tolerance double precision DEFAULT 0)
 RETURNS SETOF bigint
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$TopoGeo_AddPolygon$function$
;

CREATE OR REPLACE FUNCTION topology.topogeo_loadgeometry(atopology character varying, ageom geometry, tolerance double precision DEFAULT 0)
 RETURNS void
 LANGUAGE c
AS '$libdir/postgis_topology-3', $function$TopoGeo_LoadGeometry$function$
;

CREATE OR REPLACE FUNCTION topology.topogeom_addelement(tg topogeometry, el topoelement)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  toponame TEXT;
  sql TEXT;
BEGIN

  -- Get topology name
  BEGIN
    SELECT name
    FROM topology.topology
      INTO STRICT toponame WHERE id = topology_id(tg);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'No topology with name "%" in topology.topology',
        atopology;
  END;

  -- Insert new element
  sql := format('INSERT INTO %s.relation'
         '(topogeo_id,layer_id,element_id,element_type)'
         ' VALUES($1,$2,$3,$4)', quote_ident(toponame));
  BEGIN
    EXECUTE sql USING id(tg), layer_id(tg), el[1], el[2];
  EXCEPTION
    WHEN unique_violation THEN
      -- already present, let go
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Got % (%)', SQLERRM, SQLSTATE;
  END;

  RETURN tg;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.topogeom_addtopogeom(tgt topogeometry, src topogeometry)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  sql TEXT;
  topo topology.topology;
  srcElementTypes int[];
  srcLayer topology.layer;
  tgtLayer topology.layer;
  maxElemType int;
BEGIN

  -- Get topology information
  topo := topology.FindTopology(topology_id(src));


  IF topology_id(src) != topology_id(tgt) THEN
    RAISE EXCEPTION 'Source and target TopoGeometry objects need be defined on the same topology';
  END IF;


  SELECT * FROM topology.layer
  WHERE topology_id = topo.id
    AND layer_id = layer_id(src)
  INTO srcLayer;

  SELECT * FROM topology.layer
  WHERE topology_id = topo.id
    AND layer_id = layer_id(tgt)
  INTO tgtLayer;

  -- Check simple/hierarchical compatibility
  IF srcLayer.child_id IS NULL THEN
    IF srcLayer.child_id IS NOT NULL THEN
      RAISE EXCEPTION 'Cannot add components of hierarchical TopoGeometry to a non-hierarchical TopoGeometry';
    END IF;
  ELSIF tgtLayer.child_id IS NULL THEN
      RAISE EXCEPTION 'Cannot add components of non-hierarchical TopoGeometry to a hierarchical TopoGeometry';
  ELSIF tgtLayer.child_id != srcLayer.childId THEN
      RAISE EXCEPTION 'Cannot add components of hierarchical TopoGeometry to a hierarchical TopoGeometry based on different layer';
  END IF;

  -- Add every element of the source TopoGeometry to
  -- the definition of the target TopoGeometry
  sql := format($$
WITH inserted AS (
  INSERT INTO %1$I.relation(
    topogeo_id,
    layer_id,
    element_id,
    element_type
  )
  SELECT %2$s, %3$s, element_id, element_type
  FROM %1$I.relation
  WHERE topogeo_id = %4$L
  AND layer_id = %5$L
  EXCEPT
  SELECT %2$s, %3$s, element_id, element_type
  FROM %1$I.relation
  WHERE topogeo_id = %2$L
  AND layer_id = %3$L
  RETURNING element_type
)
SELECT array_agg(DISTINCT element_type) FROM inserted
    $$,
    topo.name,      -- %1
    id(tgt),        -- %2
    layer_id(tgt),  -- %3
    id(src),        -- %4
    layer_id(src)   -- %5
  );

  RAISE DEBUG 'SQL: %', sql;

  EXECUTE sql INTO srcElementTypes;

  -- TODO: Check layer's feature_type compatibility ?
  -- or let the relationTrigger take care of it ?
--  IF tgtLayer.feature_type != 4 THEN -- 'mixed' typed target can accept anything
--    IF srcLayer.feature_type != tgtLayer.feature_type THEN
--    END IF;
--  END IF;

  RAISE DEBUG 'Target type: %', type(tgt);
  RAISE DEBUG 'Detected source element types: %', srcElementTypes;

  -- Check if target TopoGeometry type needs be changed
  IF type(tgt) != 4 -- collection TopoGeometry accept anything
  THEN
    IF array_upper(srcElementTypes, 1) > 1
    OR srcElementTypes[1] != tgt.type
    THEN
      -- source is mixed-typed or typed differently from
      -- target, so we turn target type to collection
      RAISE DEBUG 'Changing target element type to collection';
      tgt.type = 4;
    END IF;
  END IF;




  RETURN tgt;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.topogeom_remelement(tg topogeometry, el topoelement)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  toponame TEXT;
  sql TEXT;
BEGIN

  -- Get topology name
  BEGIN
    SELECT name
    FROM topology.topology
      INTO STRICT toponame WHERE id = topology_id(tg);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'No topology with name "%" in topology.topology',
        atopology;
  END;

  -- Delete the element
  sql := format('DELETE FROM %s.relation WHERE '
         'topogeo_id = $1 AND layer_id = $2 AND '
         'element_id = $3 AND element_type = $4',
         quote_ident(toponame));
  EXECUTE sql USING id(tg), layer_id(tg), el[1], el[2];

  RETURN tg;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.topologysummary(atopology character varying)
 RETURNS text
 LANGUAGE plpgsql
 STABLE STRICT
AS $function$
DECLARE
  rec RECORD;
  rec2 RECORD;
  var_topology_id integer;
  n int4;
  missing int4;
  sql text;
  ret text;
  tgcount int4;
BEGIN

  ret := 'Topology ' || quote_ident(atopology) ;

  BEGIN
    SELECT * FROM topology.topology WHERE name = atopology INTO STRICT rec;
    -- TODO: catch <no_rows> to give a nice error message
    var_topology_id := rec.id;

    ret := ret || ' (id ' || rec.id || ', '
               || 'SRID ' || rec.srid || ', '
               || 'precision ' || rec.precision;
    IF rec.hasz THEN ret := ret || ', has Z'; END IF;
    IF rec.useslargeids THEN ret := ret || ', uses Large IDs'; END IF;
    ret := ret || E')\n';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ret := ret || E' (unregistered)\n';
  END;

  BEGIN
    EXECUTE 'SELECT count(*) FROM ' || quote_ident(atopology)
      || '.node ' INTO STRICT n;
    ret = ret || n || ' nodes, ';
  EXCEPTION
    WHEN UNDEFINED_TABLE OR INVALID_SCHEMA_NAME THEN
      IF NOT EXISTS (
          SELECT * FROM pg_catalog.pg_namespace WHERE nspname = atopology
         )
      THEN
        ret = ret || 'missing schema';
        RETURN ret;
      ELSE
        ret = ret || 'missing nodes, ';
      END IF;
  END;

  BEGIN
    EXECUTE 'SELECT count(*) FROM ' || quote_ident(atopology)
      || '.edge' INTO STRICT n;
    ret = ret || n || ' edges, ';
  EXCEPTION
    WHEN UNDEFINED_TABLE OR INVALID_SCHEMA_NAME THEN
      ret = ret || 'missing edges, ';
  END;

  BEGIN
    EXECUTE format(
      $$
    SELECT
      count(*) FILTER (WHERE face_id > 0) p,
      count(*) FILTER (WHERE face_id < 0) n
    FROM %I.face
      $$,
      atopology)
    INTO STRICT rec;
    IF rec.n > 0 THEN
      ret = ret || rec.p || '? faces (pending detection), ';
    ELSE
      ret = ret || rec.p || ' faces, ';
    END IF;
  EXCEPTION
    WHEN UNDEFINED_TABLE OR UNDEFINED_COLUMN OR INVALID_SCHEMA_NAME THEN
      ret = ret || 'missing faces, ';
  END;

  BEGIN
    EXECUTE 'SELECT count(distinct layer_id) AS ln, '
      || 'count(distinct (layer_id,topogeo_id)) AS tn FROM '
      || quote_ident(atopology) || '.relation' INTO STRICT rec;
    tgcount := rec.tn;
    ret = ret || rec.tn || ' topogeoms in ' || rec.ln || E' layers\n';
  EXCEPTION
    WHEN UNDEFINED_TABLE THEN
      ret = ret || E'missing relations\n';
    WHEN UNDEFINED_COLUMN THEN
      ret = ret || E'corrupted relations\n';
  END;

  -- print information about registered layers
  FOR rec IN SELECT * FROM topology.layer l
    WHERE l.topology_id = var_topology_id
    ORDER by layer_id
  LOOP -- {
    ret = ret || 'Layer ' || rec.layer_id || ', type ';
    CASE
      WHEN rec.feature_type = 1 THEN
        ret = ret || 'Puntal';
      WHEN rec.feature_type = 2 THEN
        ret = ret || 'Lineal';
      WHEN rec.feature_type = 3 THEN
        ret = ret || 'Polygonal';
      WHEN rec.feature_type = 4 THEN
        ret = ret || 'Mixed';
      ELSE
        ret = ret || '???';
    END CASE;

    ret = ret || ' (' || rec.feature_type || '), ';

    BEGIN

      EXECUTE 'SELECT count(*) FROM ( SELECT DISTINCT topogeo_id FROM '
        || quote_ident(atopology)
        || '.relation r WHERE r.layer_id = ' || rec.layer_id
        || ' ) foo ' INTO STRICT n;

      ret = ret || n || ' topogeoms' || E'\n';

    EXCEPTION WHEN UNDEFINED_TABLE OR UNDEFINED_COLUMN THEN
      n := NULL;
      ret = ret || 'X topogeoms' || E'\n';
    END;

      IF rec.level > 0 THEN
        ret = ret || ' Hierarchy level ' || rec.level
                  || ', child layer ' || rec.child_id || E'\n';
      END IF;

      ret = ret || ' Deploy: ';
      IF rec.feature_column != '' THEN
        ret = ret || quote_ident(rec.schema_name) || '.'
                  || quote_ident(rec.table_name) || '.'
                  || quote_ident(rec.feature_column);

        IF n > 0 THEN
          sql := format(
            $$
SELECT count(*) FROM (
  SELECT topogeo_id
  FROM %1$I.relation r
  WHERE r.layer_id = %2$L
    EXCEPT
  SELECT DISTINCT id(%3$I)
  FROM %4$I.%5$I
  WHERE layer_id(%3$I) = %2$L
    AND topology_id(%3$I) = %6$L
) as foo
            $$,
            atopology,
            rec.layer_id,
            rec.feature_column,
            rec.schema_name,
            rec.table_name,
            var_topology_id
          );
          BEGIN
            RAISE DEBUG 'Executing %', sql;
            EXECUTE sql INTO STRICT missing;
            IF missing > 0 THEN
              ret = ret || ' (' || missing || ' missing topogeoms)';
            END IF;
          EXCEPTION
            WHEN UNDEFINED_TABLE THEN
              ret = ret || ' ( unexistent table )';
            WHEN UNDEFINED_COLUMN THEN
              ret = ret || ' ( unexistent column )';
          END;
        END IF;
        ret = ret || E'\n';

      ELSE
        ret = ret || E'NONE (detached)\n';
      END IF;

  END LOOP; -- }

  -- print information about unregistered layers containing topogeoms
  IF tgcount > 0 THEN -- {

    sql := 'SELECT layer_id FROM '
        || quote_ident(atopology) || '.relation EXCEPT SELECT layer_id'
        || ' FROM topology.layer WHERE topology_id = $1 ORDER BY layer_id';
    --RAISE DEBUG '%', sql;
    FOR rec IN  EXECUTE sql USING var_topology_id
    LOOP -- {
      ret = ret || 'Layer ' || rec.layer_id::text || ', UNREGISTERED, ';

      EXECUTE 'SELECT count(*) FROM ( SELECT DISTINCT topogeo_id FROM '
        || quote_ident(atopology)
        || '.relation r WHERE r.layer_id = ' || rec.layer_id
        || ' ) foo ' INTO STRICT n;

      ret = ret || n || ' topogeoms' || E'\n';

    END LOOP; -- }

  END IF; -- }

  RETURN ret;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.totaltopologysize(toponame name)
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  sql TEXT;
  total_size int8;
BEGIN
  sql := format(
    $$
SELECT
pg_catalog.pg_total_relation_size('%1$I.edge_data') +
pg_catalog.pg_total_relation_size('%1$I.node') +
pg_catalog.pg_total_relation_size('%1$I.face') +
pg_catalog.pg_total_relation_size('%1$I.relation')
    $$,
    toponame
  );

  EXECUTE sql INTO total_size;
  RETURN total_size;

END;
$function$
;

CREATE OR REPLACE FUNCTION topology.totopogeom(ageom geometry, atopology character varying, alayer integer, atolerance double precision DEFAULT 0)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  layer_info RECORD;
  topology_info RECORD;
  tg topology.TopoGeometry;
  typ TEXT;
BEGIN

  -- Get topology information
  BEGIN
    SELECT *
    FROM topology.topology
      INTO STRICT topology_info WHERE name = atopology;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'No topology with name "%" in topology.topology',
        atopology;
  END;

  -- Get layer information
  BEGIN
    SELECT *, CASE
      WHEN feature_type = 1 THEN 'puntal'
      WHEN feature_type = 2 THEN 'lineal'
      WHEN feature_type = 3 THEN 'areal'
      WHEN feature_type = 4 THEN 'mixed'
      ELSE 'unexpected_'||feature_type
      END as typename
    FROM topology.layer l
      INTO STRICT layer_info
      WHERE l.layer_id = alayer
      AND l.topology_id = topology_info.id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'No layer with id "%" in topology "%"',
        alayer, atopology;
  END;

  -- Can't convert to a hierarchical topogeometry
  IF layer_info.level > 0 THEN
      RAISE EXCEPTION 'Layer "%" of topology "%" is hierarchical, cannot convert to it.',
        alayer, atopology;
  END IF;

  --
  -- Check type compatibility and create empty TopoGeometry
  -- 1:puntal, 2:lineal, 3:areal, 4:collection
  --
  typ = geometrytype(ageom);
  IF typ = 'GEOMETRYCOLLECTION' THEN
    --  A collection can only go collection layer
    IF layer_info.feature_type != 4 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a collection feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg := topology.CreateTopoGeom(atopology, 4, alayer);
  ELSIF typ = 'POINT' OR typ = 'MULTIPOINT' THEN -- puntal
    --  A point can go in puntal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 1 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a puntal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg := topology.CreateTopoGeom(atopology, 1, alayer);
  ELSIF typ = 'LINESTRING' or typ = 'MULTILINESTRING' THEN -- lineal
    --  A line can go in lineal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 2 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a lineal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg := topology.CreateTopoGeom(atopology, 2, alayer);
  ELSIF typ = 'POLYGON' OR typ = 'MULTIPOLYGON' THEN -- areal
    --  An area can go in areal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 3 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold an areal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg := topology.CreateTopoGeom(atopology, 3, alayer);
  ELSE
      -- Should never happen
      RAISE EXCEPTION
        'Unsupported feature type %', typ;
  END IF;

  tg := topology.toTopoGeom(ageom, tg, atolerance);

  RETURN tg;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.totopogeom(ageom geometry, tg topogeometry, atolerance double precision DEFAULT 0)
 RETURNS topogeometry
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  layer_info RECORD;
  topology_info RECORD;
  rec RECORD;
  rec2 RECORD;
  elem TEXT;
  elems TEXT[];
  sql TEXT;
  typ TEXT;
  tolerance FLOAT8;
  alayer INT;
  atopology TEXT;
BEGIN


  -- Get topology information
  SELECT id, name FROM topology.topology
    INTO topology_info
    WHERE id = topology_id(tg);
  IF NOT FOUND THEN
    RAISE EXCEPTION 'No topology with id "%" in topology.topology',
                    topology_id(tg);
  END IF;

  alayer := layer_id(tg);
  atopology := topology_info.name;

  -- Get tolerance, if 0 was given
  tolerance := COALESCE( NULLIF(atolerance, 0), topology._st_mintolerance(topology_info.name, ageom) );

  -- Get layer information
  BEGIN
    SELECT *, CASE
      WHEN feature_type = 1 THEN 'puntal'
      WHEN feature_type = 2 THEN 'lineal'
      WHEN feature_type = 3 THEN 'areal'
      WHEN feature_type = 4 THEN 'mixed'
      ELSE 'unexpected_'||feature_type
      END as typename
    FROM topology.layer l
      INTO STRICT layer_info
      WHERE l.layer_id = layer_id(tg)
      AND l.topology_id = topology_info.id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE EXCEPTION 'No layer with id "%" in topology "%"',
        alayer, atopology;
  END;

  -- Can't convert to a hierarchical topogeometry
  IF layer_info.level > 0 THEN
      RAISE EXCEPTION 'Layer "%" of topology "%" is hierarchical, cannot convert a simple geometry to it.',
        alayer, atopology;
  END IF;

  --
  -- Check type compatibility and set TopoGeometry type
  -- 1:puntal, 2:lineal, 3:areal, 4:collection
  --
  typ = geometrytype(ageom);
  IF typ = 'GEOMETRYCOLLECTION' THEN
    --  A collection can only go to collection layer
    IF layer_info.feature_type != 4 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a collection feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg.type := 4;
  ELSIF typ = 'POINT' OR typ = 'MULTIPOINT' THEN -- puntal
    --  A point can go in puntal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 1 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a puntal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg.type := CASE WHEN tg.type = 1 THEN 1 ELSE 4 END;
  ELSIF typ = 'LINESTRING' or typ = 'MULTILINESTRING' THEN -- lineal
    --  A line can go in lineal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 2 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold a lineal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg.type := CASE WHEN tg.type = 2 THEN 2 ELSE 4 END;
  ELSIF typ = 'POLYGON' OR typ = 'MULTIPOLYGON' THEN -- areal
    --  An area can go in areal or collection layer
    IF layer_info.feature_type != 4 and layer_info.feature_type != 3 THEN
      RAISE EXCEPTION
        'Layer "%" of topology "%" is %, cannot hold an areal feature.',
        layer_info.layer_id, topology_info.name, layer_info.typename;
    END IF;
    tg.type := CASE WHEN tg.type = 3 THEN 3 ELSE 4 END;
  ELSE
      -- Should never happen
      RAISE EXCEPTION
        'Unexpected feature dimension %', ST_Dimension(ageom);
  END IF;

  -- Now that we have an empty topogeometry, we loop over distinct components
  -- and add them to the definition of it. We add them as soon
  -- as possible so that each element can further edit the
  -- definition by splitting
  FOR rec IN SELECT id(tg), alayer as lyr,
    geom, ST_Dimension(gd.geom) as dims
    FROM ST_Dump(ageom) AS gd
    WHERE NOT ST_IsEmpty(gd.geom)
  LOOP
    -- NOTE: Switched from using case to this because of PG 10 behavior change
    -- Using a UNION ALL only one will be processed because of the WHERE
    -- Since the WHERE clause will be processed first
    FOR rec2 IN SELECT primitive
          FROM
            (
              SELECT topology.topogeo_addPoint(atopology, rec.geom, tolerance)
                WHERE rec.dims = 0
              UNION ALL
              SELECT topology.topogeo_addLineString(atopology, rec.geom, tolerance)
                WHERE rec.dims = 1
              UNION ALL
              SELECT topology.topogeo_addPolygon(atopology, rec.geom, tolerance)
                WHERE rec.dims = 2
            ) AS f(primitive)
    LOOP
      elem := ARRAY[rec.dims+1, rec2.primitive]::text;
      IF elems @> ARRAY[elem] THEN
      ELSE
        elems := elems || elem;
        -- TODO: consider use a single INSERT statement for the whole thing
        sql := 'INSERT INTO ' || quote_ident(atopology)
            || '.relation(topogeo_id, layer_id, element_type, element_id) VALUES ('
            || rec.id || ',' || rec.lyr || ',' || rec.dims+1
            || ',' || rec2.primitive || ')'
            -- NOTE: we're avoiding duplicated rows here
            || ' EXCEPT SELECT ' || rec.id || ', ' || rec.lyr
            || ', element_type, element_id FROM '
            || quote_ident(topology_info.name)
            || '.relation WHERE layer_id = ' || rec.lyr
            || ' AND topogeo_id = ' || rec.id;
        EXECUTE sql;
      END IF;
    END LOOP;
  END LOOP;

  RETURN tg;

END
$function$
;

CREATE OR REPLACE FUNCTION topology.upgradetopology(toponame name)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  sql TEXT;
  topo topology.topology;
  face_currval INT;
  edge_currval INT;
  node_currval INT;
BEGIN
  topo := findTopology(toponame);
  IF topo.id IS NULL THEN
    RAISE EXCEPTION 'Could not find topology "%"', toponame;
  END IF;

  -- Check if topology already uses large ids
  IF topo.useslargeids THEN
    RAISE EXCEPTION 'Topology "%" is already upgraded to use large ids', toponame;
  END IF;

  -- Get face sequence current value
  EXECUTE format(
    $$
    SELECT last_value
    FROM %1$I.face_face_id_seq
    $$,
    toponame
  ) INTO face_currval;

  -- Get edge sequence current value
  EXECUTE format(
    $$
    SELECT last_value
    FROM %1$I.edge_data_edge_id_seq
    $$,
    toponame
  ) INTO edge_currval;

  -- Get node sequence current value
  EXECUTE format(
    $$
    SELECT last_value
    FROM %1$I.node_node_id_seq
    $$,
    toponame
  ) INTO node_currval;

  sql := format(
    $$
		-- Upgrade the face table
		ALTER TABLE %1$I.face
    	ALTER COLUMN face_id TYPE BIGINT;

		ALTER TABLE %1$I.face
    	ALTER COLUMN face_id DROP DEFAULT;

		DROP SEQUENCE %1$I.face_face_id_seq;

		CREATE SEQUENCE %1$I.face_face_id_seq AS BIGINT;

		SELECT setval('%1$I.face_face_id_seq', %2$s);

		ALTER TABLE %1$I.face
      ALTER COLUMN face_id SET DEFAULT nextval('%1$I.face_face_id_seq');

		-- Upgrade the edge_data table
  	-- Drop the edge view
    DROP VIEW IF EXISTS %1$I.edge;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN edge_id TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN edge_id DROP DEFAULT;

		DROP SEQUENCE %1$I.edge_data_edge_id_seq;

		CREATE SEQUENCE %1$I.edge_data_edge_id_seq AS BIGINT;

		SELECT setval('%1$I.edge_data_edge_id_seq', %3$s);

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN edge_id SET DEFAULT nextval('%1$I.edge_data_edge_id_seq');

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN left_face TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN right_face TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN next_left_edge TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN abs_next_left_edge TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN next_right_edge TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN abs_next_right_edge TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN start_node TYPE BIGINT;

		ALTER TABLE %1$I.edge_data
    	ALTER COLUMN end_node TYPE BIGINT;

		-- edge standard view (select rule)
		CREATE VIEW %1$I.edge AS
		SELECT
			edge_id, start_node, end_node, next_left_edge,
			next_right_edge, left_face, right_face, geom
		FROM %1$I.edge_data;

		-- Edge standard view description
		COMMENT ON VIEW %1$I.edge IS
		'Contains edge topology primitives';
		COMMENT ON COLUMN %1$I.edge.edge_id IS
		'Unique identifier of the edge';
		COMMENT ON COLUMN %1$I.edge.start_node IS
		'Unique identifier of the node at the start of the edge';
		COMMENT ON COLUMN %1$I.edge.end_node IS
		'Unique identifier of the node at the end of the edge';
		COMMENT ON COLUMN %1$I.edge.next_left_edge IS
		'Unique identifier of the next edge of the face on the left (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';
		COMMENT ON COLUMN %1$I.edge.next_right_edge IS
		'Unique identifier of the next edge of the face on the right (when looking in the direction from START_NODE to END_NODE), moving counterclockwise around the face boundary';
		COMMENT ON COLUMN %1$I.edge.left_face IS
		'Unique identifier of the face on the left side of the edge when looking in the direction from START_NODE to END_NODE';
		COMMENT ON COLUMN %1$I.edge.right_face IS
		'Unique identifier of the face on the right side of the edge when looking in the direction from START_NODE to END_NODE';
		COMMENT ON COLUMN %1$I.edge.geom IS
		'The geometry of the edge';

		-- edge standard view (insert rule)
		CREATE RULE edge_insert_rule AS
		ON INSERT TO %1$I.edge
		DO INSTEAD INSERT into %1$I.edge_data
		VALUES (
			NEW.edge_id, NEW.start_node, NEW.end_node,
			NEW.next_left_edge, abs(NEW.next_left_edge),
			NEW.next_right_edge, abs(NEW.next_right_edge),
			NEW.left_face, NEW.right_face, NEW.geom
		);

		-- Upgrade the node table
	  ALTER TABLE %1$I.node
	    ALTER COLUMN node_id TYPE BIGINT;

	  ALTER TABLE %1$I.node
	    ALTER COLUMN node_id DROP DEFAULT;

    DROP SEQUENCE %1$I.node_node_id_seq;

    CREATE SEQUENCE %1$I.node_node_id_seq AS BIGINT;

		SELECT setval('%1$I.node_node_id_seq', %4$s);

		ALTER TABLE %1$I.node
    	ALTER COLUMN node_id SET DEFAULT nextval('%1$I.node_node_id_seq');

	  ALTER TABLE %1$I.node
	    ALTER COLUMN containing_face TYPE BIGINT;

		-- Upgrade the relation table
	  ALTER TABLE %1$I.relation
	    ALTER COLUMN topogeo_id TYPE BIGINT;

	  ALTER TABLE %1$I.relation
	    ALTER COLUMN element_id TYPE BIGINT;

  		-- Update the topology table
	  UPDATE topology.topology
	  SET useslargeids = true
	  WHERE id = %5$s;
    $$,
    toponame,
    face_currval,
    edge_currval,
    node_currval,
    topo.id
  );

  --RAISE INFO '%', sql;
  EXECUTE sql;
END;
$function$
;

CREATE OR REPLACE FUNCTION topology.validatetopology(toponame character varying, bbox geometry DEFAULT NULL::geometry)
 RETURNS SETOF validatetopology_returntype
 LANGUAGE plpgsql
AS $function$
DECLARE
  retrec topology.ValidateTopology_ReturnType;
  rec RECORD;
  rec2 RECORD;
  affected_rows integer;
  invalid_edges bigint[];
  invalid_faces bigint[];
  has_invalid_edge_linking BOOLEAN := false;
  has_invalid_rings BOOLEAN := false;
  search_path_backup text;
  containing_face bigint;
BEGIN

  IF NOT EXISTS (
    SELECT oid
    FROM pg_catalog.pg_namespace
    WHERE nspname = toponame
  )
  THEN
    RAISE EXCEPTION 'Topology schema % does not exist', toponame;
  END IF;

  IF NOT EXISTS (
    SELECT id
    FROM topology.topology
    WHERE name = toponame
  )
  THEN
    RAISE WARNING 'Topology % is not registered in topology.topology', toponame;
  END IF;

  EXECUTE 'SHOW search_path' INTO search_path_backup;
  EXECUTE 'SET search_PATH TO ' || quote_ident(toponame) || ','
                                || search_path_backup;

  IF bbox IS NOT NULL THEN
    RAISE NOTICE 'Limiting topology checking to bbox %', ST_AsEWKT(ST_Envelope(bbox));
  END IF;


  -- Check for coincident nodes
  RAISE NOTICE 'Checking for coincident nodes';
  FOR rec IN
    SELECT a.node_id as id1, b.node_id as id2
    FROM
      node a,
      node b
    WHERE a.node_id < b.node_id
    AND a.geom = b.geom
    AND (
      bbox IS NULL
      OR (
        a.geom && bbox
        AND
        b.geom && bbox
      )
    )
  LOOP
    retrec.error = 'coincident nodes';
    retrec.id1 = rec.id1;
    retrec.id2 = rec.id2;
    RETURN NEXT retrec;
  END LOOP;

  -- Check for edge crossed nodes
  -- TODO: do this in the single edge loop
  RAISE NOTICE 'Checking for edges crossing nodes';
  FOR rec IN
    SELECT n.node_id as nid, e.edge_id as eid
    FROM
      node n,
      edge e
    WHERE e.start_node != n.node_id
    AND e.end_node != n.node_id
    AND ST_Within(n.geom, e.geom)
    AND (
      bbox IS NULL
      OR (
        n.geom && bbox
        AND
        e.geom && bbox
      )
    )
  LOOP
    retrec.error = 'edge crosses node';
    retrec.id1 = rec.eid; -- edge_id
    retrec.id2 = rec.nid; -- node_id
    RETURN NEXT retrec;
  END LOOP;

  -- Scan all edges
  RAISE NOTICE 'Checking for invalid or not-simple edges';
  FOR rec IN
    SELECT e.geom, e.edge_id::int8 as id1, e.left_face::int8, e.right_face::int8
    FROM edge e
    WHERE (
      bbox IS NULL
      OR e.geom && bbox
    )
    ORDER BY edge_id
  LOOP --{

    -- Any invalid edge becomes a cancer for higher level complexes
    IF NOT ST_IsValid(rec.geom) THEN

      retrec.error = 'invalid edge';
      retrec.id1 = rec.id1;
      retrec.id2 = NULL;
      RETURN NEXT retrec;
      invalid_edges := array_append(invalid_edges, rec.id1);

      IF invalid_faces IS NULL OR NOT rec.left_face = ANY ( invalid_faces )
      THEN
        invalid_faces := array_append(invalid_faces, rec.left_face);
      END IF;

      IF rec.right_face != rec.left_face AND ( invalid_faces IS NULL OR
            NOT rec.right_face = ANY ( invalid_faces ) )
      THEN
        invalid_faces := array_append(invalid_faces, rec.right_face);
      END IF;

      CONTINUE;

    END IF;

    -- Check edge being simple (ie: not self-intersecting)
    IF NOT ST_IsSimple(rec.geom) THEN
      retrec.error = 'edge not simple';
      retrec.id1 = rec.id1;
      retrec.id2 = NULL;
      RETURN NEXT retrec;
    END IF;

  END LOOP; --}

  -- Check for edge crossing
  RAISE NOTICE 'Checking for crossing edges';
  FOR rec IN
    SELECT
      e1.edge_id as id1,
      e2.edge_id as id2,
      e1.geom as g1,
      e2.geom as g2,
      ST_Relate(e1.geom, e2.geom, 2) as im
    FROM
      edge e1,
      edge e2
    WHERE
      e1.edge_id < e2.edge_id
      AND e1.geom && e2.geom
      AND (
        invalid_edges IS NULL OR (
          NOT e1.edge_id = ANY (invalid_edges)
          AND
          NOT e2.edge_id = ANY (invalid_edges)
        )
      )
      AND (
        bbox IS NULL
        OR (
          e1.geom && bbox
          AND
          e2.geom && bbox
        )
      )
  LOOP --{

    IF ST_RelateMatch(rec.im, 'FF*F*****') THEN
      -- no interior-interior or interior-boundary intersections
      CONTINUE;
    END IF;

    retrec.error = 'edge crosses edge';
    retrec.id1 = rec.id1;
    retrec.id2 = rec.id2;
    RETURN NEXT retrec;
  END LOOP; --}

  -- Check for edge start_node geometry mismatch
  -- TODO: move this in the first edge table scan
  RAISE NOTICE 'Checking for edges start_node mismatch';
  FOR rec IN
    SELECT e.edge_id as id1, n.node_id as id2
    FROM
      edge e,
      node n
    WHERE e.start_node = n.node_id
    AND NOT ST_Equals(ST_StartPoint(e.geom), n.geom)
    AND (
      bbox IS NULL
      OR e.geom && bbox
    )
  LOOP --{
    retrec.error = 'edge start node geometry mismatch';
    retrec.id1 = rec.id1;
    retrec.id2 = rec.id2;
    RETURN NEXT retrec;
  END LOOP; --}

  -- Check for edge end_node geometry mismatch
  -- TODO: move this in the first edge table scan
  RAISE NOTICE 'Checking for edges end_node mismatch';
  FOR rec IN
    SELECT e.edge_id as id1, n.node_id as id2
    FROM
      edge e,
      node n
    WHERE e.end_node = n.node_id
    AND NOT ST_Equals(ST_EndPoint(e.geom), n.geom)
    AND (
      bbox IS NULL
      OR e.geom && bbox
    )
  LOOP --{
    retrec.error = 'edge end node geometry mismatch';
    retrec.id1 = rec.id1;
    retrec.id2 = rec.id2;
    RETURN NEXT retrec;
  END LOOP; --}

  -- Check for faces w/out edges
  RAISE NOTICE 'Checking for faces without edges';
  FOR rec IN
    SELECT f.face_id::int8 as id1
    FROM face f
    LEFT JOIN edge_data e ON (
      f.face_id = e.left_face OR
      f.face_id = e.right_face
    )
    WHERE f.face_id > 0
    AND (
      bbox IS NULL
      OR mbr && bbox
    )
    AND e.edge_id IS NULL
  LOOP --{
    invalid_faces := array_append(invalid_faces, rec.id1);
    retrec.error = 'face without edges';
    retrec.id1 = rec.id1;
    retrec.id2 = NULL;
    RETURN NEXT retrec;
  END LOOP; --}

  -- Validate edge linking
  -- NOTE: relies on correct start_node/end_node on edges
  FOR rec IN SELECT * FROM topology._ValidateTopologyEdgeLinking(bbox)
  LOOP
    RETURN next rec;
    has_invalid_edge_linking := true;
  END LOOP;

  IF has_invalid_edge_linking THEN
    DROP TABLE IF EXISTS pg_temp.hole_check;
    DROP TABLE IF EXISTS pg_temp.shell_check;
    RETURN; -- does not make sense to continue
  END IF;

  --- Validate edge rings
  FOR rec IN SELECT * FROM topology._ValidateTopologyRings(bbox)
  LOOP
    RETURN next rec;
    has_invalid_rings := true;
  END LOOP;

  IF has_invalid_rings THEN
    DROP TABLE IF EXISTS pg_temp.hole_check;
    DROP TABLE IF EXISTS pg_temp.shell_check;
    RETURN; -- does not make sense to continue
  END IF;

  -- Now create a temporary table to construct all face geometries
  -- for checking their consistency

  RAISE NOTICE 'Constructing geometry of all faces';
  -- TODO: only construct exterior ring

  CREATE TEMP TABLE face_check ON COMMIT DROP AS
  SELECT
    sc.face_id,
    sc.ring_geom AS shell,
    f.mbr
  FROM
    pg_temp.shell_check sc, face f
  WHERE
    f.face_id = sc.face_id
  ;


  DROP TABLE pg_temp.shell_check;

  --
  -- Add to face_check any missing face whose mbr overlaps
  -- the given one.
  --
  -- This is done to still be able to check MBR consistency
  -- See https://trac.osgeo.org/postgis/ticket/5766#comment:6
  --
  INSERT INTO pg_temp.face_check
  SELECT face_id,
    CASE WHEN face_id = 0 THEN
      NULL
    ELSE
      topology._ValidateTopologyGetFaceShellMaximalEdgeRing(toponame, face_id)
    END as real_shell,
    mbr
  FROM face
  WHERE ( bbox IS NULL OR mbr && bbox )
  AND (
    CASE WHEN invalid_faces IS NOT NULL THEN
      NOT face_id = ANY(invalid_faces)
    ELSE
      TRUE
    END
  )
  AND face_id NOT IN (
    SELECT face_id FROM pg_temp.face_check
  );


  -- Build a gist index on geom
  CREATE INDEX ON face_check USING gist (shell);

  -- Build a btree index on id
  CREATE INDEX ON face_check (face_id);

  -- Scan the table looking for NULL geometries
  -- or geometries with wrong MBR consistency
  RAISE NOTICE 'Checking faces';
  affected_rows := 0;
  FOR rec IN
    SELECT * FROM face_check
  LOOP --{

    affected_rows := affected_rows + 1;

    IF rec.face_id != 0 THEN -- {

      -- Real face need have rings and matching MBR

      IF rec.shell IS NULL OR ST_IsEmpty(rec.shell)
      THEN
        -- Face missing !
        retrec.error := 'face has no rings';
        retrec.id1 := rec.face_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      END IF;

      IF NOT ST_Equals(rec.mbr, ST_Envelope(rec.shell))
      THEN
        -- Inconsistent MBR!
        retrec.error := 'face has wrong mbr';
        retrec.id1 := rec.face_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      END IF;

    ELSE --}{

      -- Universal face need have no shell rings and NULL MBR

      IF rec.shell IS NOT NULL OR NOT ST_IsEmpty(rec.shell)
      THEN
        retrec.error := 'universal face has shell rings';
        retrec.id1 := rec.face_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      END IF;

      IF rec.mbr IS NOT NULL
      THEN
        -- TODO: make the message more specific about universal face ?
        retrec.error := 'face has wrong mbr';
        retrec.id1 := rec.face_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      END IF;

    END IF; --}

  END LOOP; --}

  RAISE NOTICE 'Checked % faces', affected_rows;

  -- Check edges are covered by their left-right faces (#4830)
  RAISE NOTICE 'Checking for holes coverage';
  affected_rows := 0;
  FOR rec IN
    SELECT * FROM hole_check
  LOOP --{
    SELECT f.face_id
    FROM face_check f
    WHERE rec.hole_mbr @ f.shell
    AND _ST_Contains(f.shell, rec.hole_point)
    ORDER BY ST_Area(f.shell) ASC
    LIMIT 1
    INTO rec2;

    IF ( NOT FOUND AND rec.in_shell != 0 )
       OR ( rec2.face_id != rec.in_shell )
    THEN
        retrec.error := 'hole not in advertised face';
        retrec.id1 := rec.ring_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
    END IF;
    affected_rows := affected_rows + 1;

  END LOOP; --}

  RAISE NOTICE 'Finished checking for coverage of % holes', affected_rows;

  -- Check nodes have correct containing_face (#3233)
  -- NOTE: relies on correct edge linking
  RAISE NOTICE 'Checking for node containing_face correctness';
  FOR rec IN
    SELECT
      n.node_id,
      n.geom geom,
      n.containing_face,
      e.edge_id
    FROM node n
    LEFT JOIN edge e ON (
      e.start_node = n.node_id OR
      e.end_node = n.node_id
    )
    WHERE
     ( bbox IS NULL OR n.geom && bbox )
  LOOP --{

    IF rec.edge_id IS NOT NULL
    THEN --{
      -- Node is not isolated, make sure it
      -- advertises itself as such
      IF rec.containing_face IS NOT NULL
      THEN --{
        -- node is not really isolated
        retrec.error := 'not-isolated node has not-null containing_face';
        retrec.id1 := rec.node_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      END IF; --}
    ELSE -- }{
      -- Node is isolated, make sure it
      -- advertises itself as such
      IF rec.containing_face IS NULL
      THEN --{
        -- isolated node advertises itself as non-isolated
        retrec.error := 'isolated node has null containing_face';
        retrec.id1 := rec.node_id;
        retrec.id2 := NULL;
        RETURN NEXT retrec;
      ELSE -- }{
        -- node is isolated and advertising a containing_face
        -- now let's check it's really in contained by it
        BEGIN
          containing_face := topology.GetFaceContainingPoint(toponame, rec.geom);
        EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'Got % (%)', SQLSTATE, SQLERRM;
          retrec.error := format('got exception trying to find face containing node: %s', SQLERRM);
          retrec.id1 := rec.node_id;
          retrec.id2 := NULL;
          RETURN NEXT retrec;
        END;
        IF containing_face != rec.containing_face THEN
          retrec.error := 'isolated node has wrong containing_face';
          retrec.id1 := rec.node_id;
          retrec.id2 := NULL; -- TODO: write expected containing_face here ?
          RETURN NEXT retrec;
        END IF;
      END IF; --}
    END IF; --}

  END LOOP; --}


  DROP TABLE pg_temp.hole_check;
  DROP TABLE pg_temp.face_check;

  EXECUTE 'SET search_PATH TO ' || search_path_backup;

  RETURN;
END
$function$
;

CREATE OR REPLACE FUNCTION topology.validatetopologyprecision(toponame name, bbox geometry DEFAULT NULL::geometry, gridsize double precision DEFAULT NULL::double precision)
 RETURNS geometry
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  topo topology.topology;
  imprecisePoints GEOMETRY;
  sql TEXT;
  dataBox GEOMETRY;
  dataMagnitude FLOAT8;
  minGridSize FLOAT8;
BEGIN

  topo := findTopology(toponame);
  IF topo.id IS NULL THEN
    RAISE EXCEPTION 'Could not find topology "%"', toponame;
  END IF;

  IF gridSize IS NULL THEN
    gridSize := topo.precision;
  END IF;

  imprecisePoints = ST_SetSRID('MULTIPOINT EMPTY'::geometry, topo.srid);

  IF gridSize <= 0 THEN
    RAISE NOTICE 'Every vertex is precise with grid size %', gridSize;
    RETURN imprecisePoints;
  END IF;

  SELECT ST_Union(g) b
  FROM (
    SELECT ST_EstimatedExtent(topo.name, 'edge_data', 'geom')::geometry g
    UNION
    SELECT ST_EstimatedExtent(topo.name, 'node', 'geom')::geometry
  ) foo
  INTO dataBox;

  IF dataBox IS NULL THEN
    RAISE NOTICE 'Every vertex is precise in an empty topology';
    RETURN imprecisePoints;
  END IF;

   dataMagnitude = greatest(
      abs(ST_Xmin(dataBox)),
      abs(ST_Xmax(dataBox)),
      abs(ST_Ymin(dataBox)),
      abs(ST_Ymax(dataBox))
  );
  -- TODO: restrict data magnitude computation to given bbox ?
  minGridSize := topology._st_mintolerance(dataMagnitude);
  IF minGridSize > gridSize THEN
    RAISE EXCEPTION 'Presence of max ordinate value % requires a minimum grid size of %', dataMagnitude, minGridSize;
  END IF;

  sql := format(
    $$
WITH edgePoints AS (
  SELECT geom FROM (
    SELECT (ST_DumpPoints(geom)).geom FROM %1$I.edge
    WHERE ( $1 IS NULL OR geom && $1 )
  ) foo
  WHERE ( $1 IS NULL OR geom && $1 )
), isolatedNodes AS (
  SELECT geom FROM %1$I.node
  WHERE containing_face IS NOT NULL
  AND ( $1 IS NULL OR geom && $1 )
), allVertices AS (
  SELECT geom from edgePoints
  UNION
  SELECT geom from isolatedNodes
)
SELECT ST_Union(geom) FROM allVertices
WHERE NOT ST_Equals( ST_SnapToGrid(geom, $2), geom )
    $$,
    topo.name
  );

  EXECUTE sql USING bbox, gridSize
  INTO imprecisePoints;

  -- Return invalid vertices

  RETURN imprecisePoints;

END;

$function$
;

CREATE OR REPLACE FUNCTION topology.validatetopologyrelation(toponame character varying)
 RETURNS TABLE(error text, layer_id integer, topogeo_id bigint, element_id bigint)
 LANGUAGE plpgsql
 STRICT
AS $function$
DECLARE
  layerrec RECORD;
  rel RECORD;
  search_path_backup text;
BEGIN
  IF NOT EXISTS (
    SELECT oid
    FROM pg_catalog.pg_namespace
    WHERE nspname = toponame
  )
  THEN
    RAISE EXCEPTION 'Topology schema % does not exist', toponame;
  END IF;

  IF NOT EXISTS (
    SELECT id
    FROM topology.topology
    WHERE name = toponame
  )
  THEN
    RAISE WARNING 'Topology % is not registered in topology.topology', toponame;
  END IF;

  EXECUTE 'SHOW search_path' INTO search_path_backup;
  EXECUTE 'SET search_PATH TO ' || quote_ident(toponame) || ','
                                || search_path_backup;

  FOR layerrec IN SELECT * FROM topology.layer
  LOOP --{
    IF layerrec.child_id IS NULL
    THEN --{ Layer is simple

      -- Check that all referenced nodes exist
      FOR rel IN
        SELECT r.layer_id, r.topogeo_id, r.element_id
        FROM relation r
        WHERE r.layer_id = layerrec.layer_id
        AND r.element_type = 1
        AND r.element_id NOT IN (
          SELECT node_id FROM node
        )
      LOOP
        error := 'TopoGeometry references unexistent node';
        layer_id := rel.layer_id;
        topogeo_id := rel.topogeo_id;
        element_id := rel.element_id;
        RETURN NEXT;
      END LOOP;

      -- Check that all referenced edges exist
      FOR rel IN
        SELECT r.layer_id, r.topogeo_id, r.element_id
        FROM relation r
        WHERE r.layer_id = layerrec.layer_id
        AND r.element_type = 2
        AND abs(r.element_id) NOT IN (
          SELECT edge_id FROM edge_data
        )
      LOOP
        error := 'TopoGeometry references unexistent edge';
        layer_id := rel.layer_id;
        topogeo_id := rel.topogeo_id;
        element_id := rel.element_id;
        RETURN NEXT;
      END LOOP;

      -- Check that all referenced faces exist
      FOR rel IN
        SELECT r.layer_id, r.topogeo_id, r.element_id
        FROM relation r
        WHERE r.layer_id = layerrec.layer_id
        AND r.element_type = 3
        AND r.element_id NOT IN (
          SELECT face_id FROM face
        )
      LOOP
        error := 'TopoGeometry references unexistent face';
        layer_id := rel.layer_id;
        topogeo_id := rel.topogeo_id;
        element_id := rel.element_id;
        RETURN NEXT;
      END LOOP;

    ELSE -- }{ Layer is hierarchical

      --RAISE DEBUG 'Checking hierarchical layer %', layerrec.layer_id;

      FOR rel IN
        SELECT r.layer_id, r.topogeo_id, r.element_id
        FROM relation r
        WHERE r.layer_id = layerrec.layer_id
        AND abs(r.element_id) NOT IN (
          SELECT r2.topogeo_id
          FROM relation r2
          WHERE r2.layer_id = layerrec.child_id
        )
      LOOP
        error := 'TopoGeometry references unexistent child';
        layer_id := rel.layer_id;
        topogeo_id := rel.topogeo_id;
        element_id := rel.element_id;
        RETURN NEXT;
      END LOOP;

    END IF; --} Layer is hierarchical
  END LOOP; --}

  EXECUTE 'SET search_PATH TO ' || search_path_backup;
END;
$function$
;

