-- =============================================================================
--   AFitAccess — Schéma PostgreSQL Complet
--   Version   : 1.0
--   Date      : 10 Mai 2026
-- =============================================================================
-- ORDRE D'EXÉCUTION :
--   1. Extensions
--   2. Types énumérés (ENUMs)
--   3. Fonction trigger updated_at
--   4. Tables (ordre de dépendance)
--   5. Index
--   6. Triggers updated_at
--   7. Vues utilitaires
--   8. Fonctions utilitaires
--   9. Données initiales (seed)
-- =============================================================================

-- Encodage et paramètres
SET client_encoding = 'UTF8';
SET timezone = 'Africa/Dakar';

-- =============================================================================
-- 1. EXTENSIONS
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";        -- gen_random_uuid(), crypt()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";       -- uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "pg_trgm";         -- Recherche textuelle fuzzy
CREATE EXTENSION IF NOT EXISTS "unaccent";        -- Recherche sans accents

-- =============================================================================
-- 2. TYPES ÉNUMÉRÉS (ENUMs)
-- =============================================================================

-- Rôle super admin plateforme
CREATE TYPE role_admin_plateforme AS ENUM (
    'SUPERADMIN',
    'ADMIN',
    'SUPPORT'
);

-- Plan de licence SaaS
CREATE TYPE type_plan_licence AS ENUM (
    'GRATUIT',
    'PRO',
    'ENTREPRISE'
);

-- Statut d'une licence
CREATE TYPE statut_licence AS ENUM (
    'ACTIVE',
    'EXPIREE',
    'SUSPENDUE',
    'RESILIEE',
    'EN_ATTENTE'
);

-- Mode de facturation d'une licence
CREATE TYPE mode_facturation AS ENUM (
    'MENSUEL',
    'ANNUEL',
    'UNIQUE'
);

-- Statut d'une salle
CREATE TYPE statut_salle AS ENUM (
    'ACTIVE',
    'SUSPENDUE',
    'INACTIVE',
    'EN_ATTENTE_VALIDATION'
);

-- Rôle d'un employé de salle
CREATE TYPE role_employe AS ENUM (
    'GESTIONNAIRE',
    'CAISSIER',
    'RECEPTIONNISTE',
    'COACH',
    'SECURITE',
    'TECHNICIEN'
);

-- Sexe
CREATE TYPE sexe_membre AS ENUM (
    'HOMME',
    'FEMME',
    'NON_SPECIFIE'
);

-- Statut d'un abonnement membre
CREATE TYPE statut_abonnement AS ENUM (
    'EN_ATTENTE',
    'ACTIF',
    'SUSPENDU',
    'EXPIRE',
    'ANNULE'
);

-- Méthode d'accès à la salle
CREATE TYPE methode_acces AS ENUM (
    'QR_CODE',
    'FACE_ID',
    'QR_TEMPORAIRE',
    'PASS_JOURNALIER',
    'INVITATION_PREMIUM',
    'BADGE_MANUEL',
    'ACCES_EMPLOYE'
);

-- Résultat d'une tentative d'accès
CREATE TYPE statut_acces AS ENUM (
    'AUTORISE',
    'REFUSE_ABONNEMENT_EXPIRE',
    'REFUSE_ABONNEMENT_SUSPENDU',
    'REFUSE_QR_INVALIDE',
    'REFUSE_QR_DEJA_UTILISE',
    'REFUSE_QR_EXPIRE',
    'REFUSE_FACE_NON_RECONNU',
    'REFUSE_SALLE_FERMEE',
    'REFUSE_CAPACITE_MAX',
    'REFUSE_INVITATION_EXPIREE',
    'REFUSE_INVITATION_DEJA_UTILISEE',
    'REFUSE_MEMBRE_INACTIF',
    'ERREUR_SYSTEME'
);

-- Moyen de paiement
CREATE TYPE moyen_paiement AS ENUM (
    'ESPECES',
    'CARTE_BANCAIRE',
    'MOBILE_MONEY_WAVE',
    'MOBILE_MONEY_ORANGE',
    'MOBILE_MONEY_AUTRE',
    'VIREMENT_BANCAIRE',
    'PAIEMENT_EN_LIGNE_STRIPE',
    'PAIEMENT_EN_LIGNE_PAYDUNYA',
    'CREDIT_INTERNE'
);

-- Statut d'un paiement
CREATE TYPE statut_paiement AS ENUM (
    'EN_ATTENTE',
    'COMPLETE',
    'ECHOUE',
    'REMBOURSE',
    'PARTIELLEMENT_REMBOURSE',
    'ANNULE',
    'EN_LITIGE'
);

-- Objet d'un paiement
CREATE TYPE objet_paiement AS ENUM (
    'ABONNEMENT',
    'RENOUVELLEMENT_ABONNEMENT',
    'PASS_JOURNALIER',
    'PRODUIT',
    'CREDIT_JOURNALIER',
    'LICENCE_SALLE',
    'AUTRE'
);

-- Statut d'une commande produit
CREATE TYPE statut_commande AS ENUM (
    'EN_COURS',
    'CONFIRMEE',
    'PREPAREE',
    'EXPEDIEE',
    'LIVREE',
    'ANNULEE',
    'REMBOURSEE'
);

-- Type de promotion
CREATE TYPE type_promotion AS ENUM (
    'POURCENTAGE',
    'MONTANT_FIXE',
    'SEANCES_GRATUITES',
    'DUREE_OFFERTE',
    'PREMIER_MOIS_GRATUIT',
    'ACCES_GRATUIT'
);

-- Type de notification
CREATE TYPE canal_notification AS ENUM (
    'PUSH_WEB',
    'EMAIL',
    'SMS',
    'IN_APP'
);

-- Type de campagne marketing
CREATE TYPE type_campagne AS ENUM (
    'EMAIL_BROADCAST',
    'SMS_BROADCAST',
    'PUSH_BROADCAST',
    'RELANCE_EXPIRATION',
    'ONBOARDING',
    'ANNIVERSAIRE',
    'POST_INVITATION',
    'POST_PASS',
    'OFFRE_SPECIALE'
);

-- Statut d'une invitation premium
CREATE TYPE statut_invitation AS ENUM (
    'EN_ATTENTE',
    'ACCEPTEE',
    'REFUSEE',
    'UTILISEE',
    'EXPIREE',
    'ANNULEE'
);

-- Statut d'un lead CRM
CREATE TYPE statut_lead AS ENUM (
    'FROID',
    'CHAUD',
    'QUALIFIE',
    'CONVERTI',
    'PERDU'
);

-- Source d'un lead CRM
CREATE TYPE source_lead AS ENUM (
    'INVITATION_PREMIUM',
    'PASS_JOURNALIER',
    'FORMULAIRE_WEB',
    'RESEAUX_SOCIAUX',
    'BOUCHE_A_OREILLE',
    'PUBLICITE',
    'IMPORT_MANUEL'
);

-- Statut d'un ticket support
CREATE TYPE statut_ticket AS ENUM (
    'OUVERT',
    'EN_COURS',
    'EN_ATTENTE_CLIENT',
    'RESOLU',
    'FERME',
    'ESCALADE_ADMIN'
);

-- Priorité d'un ticket support
CREATE TYPE priorite_ticket AS ENUM (
    'BASSE',
    'NORMALE',
    'HAUTE',
    'CRITIQUE'
);

-- Type d'action pour les journaux d'audit
CREATE TYPE type_action_audit AS ENUM (
    'CREATION',
    'MODIFICATION',
    'SUPPRESSION',
    'CONNEXION',
    'DECONNEXION',
    'TENTATIVE_CONNEXION_ECHOUEE',
    'PAIEMENT',
    'REMBOURSEMENT',
    'ACCES_BORNE',
    'EXPORT_DONNEES',
    'MODIFICATION_CONFIGURATION',
    'ENVOI_NOTIFICATION',
    'SUSPENSION',
    'REACTIVATION'
);

-- Niveau de log système
CREATE TYPE niveau_log AS ENUM (
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
    'CRITICAL'
);

-- Type de consentement RGPD
CREATE TYPE type_consentement AS ENUM (
    'FACE_ID',
    'MARKETING_EMAIL',
    'MARKETING_SMS',
    'MARKETING_PUSH',
    'COOKIES_ANALYTIQUES',
    'CONDITIONS_UTILISATION',
    'POLITIQUE_CONFIDENTIALITE'
);

-- =============================================================================
-- 3. FONCTION TRIGGER — Mise à jour automatique de modifie_le
-- =============================================================================

CREATE OR REPLACE FUNCTION fn_mise_a_jour_modifie_le()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.modifie_le = NOW();
    RETURN NEW;
END;
$$;

-- =============================================================================
-- 4. TABLES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.01  admins_plateforme
--       Équipe interne AFitAccess (Super Admin, Admin, Support)
-- -----------------------------------------------------------------------------
CREATE TABLE admins_plateforme (
    id                      SERIAL          PRIMARY KEY,
    nom                     VARCHAR(100)    NOT NULL,
    prenom                  VARCHAR(100)    NOT NULL,
    email                   VARCHAR(255)    NOT NULL    UNIQUE,
    mot_de_passe_hash       VARCHAR(255)    NOT NULL,
    role                    role_admin_plateforme NOT NULL DEFAULT 'SUPPORT',
    est_actif               BOOLEAN         NOT NULL    DEFAULT TRUE,
    deux_facteurs_actif     BOOLEAN         NOT NULL    DEFAULT FALSE,
    secret_totp             VARCHAR(64),                -- Chiffré en BDD
    derniere_connexion      TIMESTAMPTZ,
    ip_derniere_connexion   INET,
    nb_tentatives_echouees  SMALLINT        NOT NULL    DEFAULT 0,
    verrouille_jusqu_a      TIMESTAMPTZ,
    token_reinit_mdp        VARCHAR(128)    UNIQUE,
    expiration_token_reinit TIMESTAMPTZ,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE admins_plateforme
    IS 'Équipe interne AFitAccess — accès au tableau de bord Super Admin';
COMMENT ON COLUMN admins_plateforme.secret_totp
    IS 'Clé secrète TOTP stockée chiffrée (AES-256) — utilisée pour 2FA';
COMMENT ON COLUMN admins_plateforme.verrouille_jusqu_a
    IS 'Compte verrouillé après 10 tentatives échouées pendant 15 minutes';

-- -----------------------------------------------------------------------------
-- 4.02  plans_licence
--       Plans tarifaires SaaS proposés aux salles
-- -----------------------------------------------------------------------------
CREATE TABLE plans_licence (
    id                  SERIAL              PRIMARY KEY,
    nom                 type_plan_licence   NOT NULL    UNIQUE,
    description         TEXT,
    prix_mensuel        NUMERIC(10, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (prix_mensuel >= 0),
    prix_annuel         NUMERIC(10, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (prix_annuel >= 0),
    max_membres         INTEGER             NOT NULL    DEFAULT 50
                            CHECK (max_membres > 0),
    max_employes        INTEGER             NOT NULL    DEFAULT 5
                            CHECK (max_employes > 0),
    max_invitations_par_membre INTEGER      NOT NULL    DEFAULT 1,
    face_id_inclus      BOOLEAN             NOT NULL    DEFAULT FALSE,
    boutique_incluse    BOOLEAN             NOT NULL    DEFAULT FALSE,
    crm_inclus          BOOLEAN             NOT NULL    DEFAULT FALSE,
    rapports_avances    BOOLEAN             NOT NULL    DEFAULT FALSE,
    support_prioritaire BOOLEAN             NOT NULL    DEFAULT FALSE,
    fonctionnalites     JSONB               NOT NULL    DEFAULT '[]'::JSONB,
    est_actif           BOOLEAN             NOT NULL    DEFAULT TRUE,
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ         NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE plans_licence
    IS 'Plans d''abonnement SaaS : GRATUIT, PRO, ENTREPRISE';
COMMENT ON COLUMN plans_licence.fonctionnalites
    IS 'Liste JSON des fonctionnalités incluses dans le plan';

-- -----------------------------------------------------------------------------
-- 4.03  salles
--       Comptes des salles de sport clientes
-- -----------------------------------------------------------------------------
CREATE TABLE salles (
    id                  SERIAL          PRIMARY KEY,
    nom_salle           VARCHAR(200)    NOT NULL,
    slug                VARCHAR(200)    NOT NULL    UNIQUE,
    description         TEXT,
    adresse             VARCHAR(300),
    ville               VARCHAR(100),
    pays                VARCHAR(100)    NOT NULL    DEFAULT 'Sénégal',
    code_postal         VARCHAR(20),
    telephone           VARCHAR(30),
    email_contact       VARCHAR(255),
    site_web            VARCHAR(300),
    logo_url            VARCHAR(500),
    siret               VARCHAR(50),                -- Numéro d'enregistrement légal
    statut              statut_salle    NOT NULL    DEFAULT 'EN_ATTENTE_VALIDATION',
    est_actif           BOOLEAN         NOT NULL    DEFAULT FALSE,
    date_inscription    DATE            NOT NULL    DEFAULT CURRENT_DATE,
    devise              VARCHAR(10)     NOT NULL    DEFAULT 'XOF',
    fuseau_horaire      VARCHAR(50)     NOT NULL    DEFAULT 'Africa/Dakar',
    langue_defaut       VARCHAR(10)     NOT NULL    DEFAULT 'fr',
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_salles_email CHECK (
        email_contact IS NULL OR email_contact ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

COMMENT ON TABLE salles IS 'Salles de sport clientes de la plateforme AFitAccess';
COMMENT ON COLUMN salles.slug IS 'Identifiant URL unique (ex: salle-fitness-dakar)';

-- -----------------------------------------------------------------------------
-- 4.04  licences_salles
--       Licences SaaS affectées aux salles
-- -----------------------------------------------------------------------------
CREATE TABLE licences_salles (
    id                  SERIAL              PRIMARY KEY,
    salle_id            INTEGER             NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    plan_id             INTEGER             NOT NULL
                            REFERENCES plans_licence(id) ON DELETE RESTRICT,
    date_debut          DATE                NOT NULL,
    date_fin            DATE                NOT NULL,
    statut              statut_licence      NOT NULL    DEFAULT 'EN_ATTENTE',
    mode_fact           mode_facturation    NOT NULL    DEFAULT 'MENSUEL',
    prix_applique       NUMERIC(10, 2)      NOT NULL    CHECK (prix_applique >= 0),
    remise_pct          NUMERIC(5, 2)       NOT NULL    DEFAULT 0.00
                            CHECK (remise_pct BETWEEN 0 AND 100),
    renouvellement_auto BOOLEAN             NOT NULL    DEFAULT TRUE,
    admin_cree_par      INTEGER
                            REFERENCES admins_plateforme(id) ON DELETE SET NULL,
    notes_internes      TEXT,
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_licences_dates CHECK (date_fin > date_debut)
);

COMMENT ON TABLE licences_salles IS 'Licences SaaS assignées aux salles (une active à la fois)';

-- -----------------------------------------------------------------------------
-- 4.05  factures_licences
--       Factures émises aux salles pour leurs licences
-- -----------------------------------------------------------------------------
CREATE TABLE factures_licences (
    id                  SERIAL              PRIMARY KEY,
    salle_id            INTEGER             NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    licence_id          INTEGER             NOT NULL
                            REFERENCES licences_salles(id) ON DELETE RESTRICT,
    numero_facture      VARCHAR(50)         NOT NULL    UNIQUE,
    montant_ht          NUMERIC(12, 2)      NOT NULL    CHECK (montant_ht >= 0),
    taux_tva            NUMERIC(5, 2)       NOT NULL    DEFAULT 18.00
                            CHECK (taux_tva BETWEEN 0 AND 100),
    montant_tva         NUMERIC(12, 2)      GENERATED ALWAYS AS
                            (ROUND(montant_ht * taux_tva / 100, 2)) STORED,
    montant_ttc         NUMERIC(12, 2)      GENERATED ALWAYS AS
                            (ROUND(montant_ht * (1 + taux_tva / 100), 2)) STORED,
    statut_paiement     statut_paiement     NOT NULL    DEFAULT 'EN_ATTENTE',
    date_emission       DATE                NOT NULL    DEFAULT CURRENT_DATE,
    date_echeance       DATE                NOT NULL,
    date_paiement       DATE,
    moyen_paiement_utl  moyen_paiement,
    reference_paiement  VARCHAR(200),
    pdf_url             VARCHAR(500),
    notes               TEXT,
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE factures_licences IS 'Factures émises aux salles pour leurs licences SaaS';
COMMENT ON COLUMN factures_licences.numero_facture
    IS 'Format recommandé : AFA-2026-00001';

-- -----------------------------------------------------------------------------
-- 4.06  gestionnaires
--       Administrateurs d'une salle (compte principal ou secondaire)
-- -----------------------------------------------------------------------------
CREATE TABLE gestionnaires (
    id                      SERIAL          PRIMARY KEY,
    salle_id                INTEGER         NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    nom                     VARCHAR(100)    NOT NULL,
    prenom                  VARCHAR(100)    NOT NULL,
    email                   VARCHAR(255)    NOT NULL    UNIQUE,
    mot_de_passe_hash       VARCHAR(255)    NOT NULL,
    telephone               VARCHAR(30),
    avatar_url              VARCHAR(500),
    est_actif               BOOLEAN         NOT NULL    DEFAULT TRUE,
    est_proprietaire        BOOLEAN         NOT NULL    DEFAULT FALSE,
    deux_facteurs_actif     BOOLEAN         NOT NULL    DEFAULT FALSE,
    secret_totp             VARCHAR(64),
    nb_tentatives_echouees  SMALLINT        NOT NULL    DEFAULT 0,
    verrouille_jusqu_a      TIMESTAMPTZ,
    token_reinit_mdp        VARCHAR(128)    UNIQUE,
    expiration_token_reinit TIMESTAMPTZ,
    derniere_connexion      TIMESTAMPTZ,
    ip_derniere_connexion   INET,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE gestionnaires
    IS 'Responsables de salles — accès au dashboard de gestion';
COMMENT ON COLUMN gestionnaires.est_proprietaire
    IS 'TRUE = propriétaire principal de la salle (créé lors de l''onboarding)';

-- -----------------------------------------------------------------------------
-- 4.07  employes
--       Employés d'une salle (caissiers, coaches, réceptionnistes...)
-- -----------------------------------------------------------------------------
CREATE TABLE employes (
    id                      SERIAL          PRIMARY KEY,
    salle_id                INTEGER         NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    gestionnaire_cree_par   INTEGER
                                REFERENCES gestionnaires(id) ON DELETE SET NULL,
    nom                     VARCHAR(100)    NOT NULL,
    prenom                  VARCHAR(100)    NOT NULL,
    email                   VARCHAR(255)    NOT NULL    UNIQUE,
    mot_de_passe_hash       VARCHAR(255)    NOT NULL,
    telephone               VARCHAR(30),
    role                    role_employe    NOT NULL    DEFAULT 'RECEPTIONNISTE',
    avatar_url              VARCHAR(500),
    est_actif               BOOLEAN         NOT NULL    DEFAULT TRUE,
    nb_tentatives_echouees  SMALLINT        NOT NULL    DEFAULT 0,
    verrouille_jusqu_a      TIMESTAMPTZ,
    token_reinit_mdp        VARCHAR(128)    UNIQUE,
    derniere_connexion      TIMESTAMPTZ,
    date_embauche           DATE,
    salaire                 NUMERIC(12, 2),
    notes_rh                TEXT,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE employes
    IS 'Employés d''une salle (caissiers, coaches, réceptionnistes...)';

-- -----------------------------------------------------------------------------
-- 4.08  horaires_employes
--       Planning hebdomadaire des employés
-- -----------------------------------------------------------------------------
CREATE TABLE horaires_employes (
    id              SERIAL      PRIMARY KEY,
    employe_id      INTEGER     NOT NULL
                        REFERENCES employes(id) ON DELETE CASCADE,
    jour_semaine    SMALLINT    NOT NULL    CHECK (jour_semaine BETWEEN 0 AND 6),
    heure_debut     TIME        NOT NULL,
    heure_fin       TIME        NOT NULL,
    est_repos       BOOLEAN     NOT NULL    DEFAULT FALSE,
    notes           VARCHAR(200),
    cree_le         TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le      TIMESTAMPTZ NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_horaires_employe_heures
        CHECK (est_repos = TRUE OR heure_fin > heure_debut),
    UNIQUE (employe_id, jour_semaine)
);

COMMENT ON COLUMN horaires_employes.jour_semaine
    IS '0 = Lundi, 1 = Mardi, ..., 6 = Dimanche';

-- -----------------------------------------------------------------------------
-- 4.09  horaires_salles
--       Horaires d'ouverture de la salle par jour de la semaine
-- -----------------------------------------------------------------------------
CREATE TABLE horaires_salles (
    id                  SERIAL      PRIMARY KEY,
    salle_id            INTEGER     NOT NULL
                            REFERENCES salles(id) ON DELETE CASCADE,
    jour_semaine        SMALLINT    NOT NULL    CHECK (jour_semaine BETWEEN 0 AND 6),
    heure_ouverture     TIME,
    heure_fermeture     TIME,
    est_ferme           BOOLEAN     NOT NULL    DEFAULT FALSE,
    message_fermeture   VARCHAR(200),
    cree_le             TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_horaires_salle_heures
        CHECK (est_ferme = TRUE OR heure_fermeture > heure_ouverture),
    UNIQUE (salle_id, jour_semaine)
);

-- -----------------------------------------------------------------------------
-- 4.10  parametres_salles
--       Configuration fonctionnelle et préférences de chaque salle
-- -----------------------------------------------------------------------------
CREATE TABLE parametres_salles (
    id                              SERIAL      PRIMARY KEY,
    salle_id                        INTEGER     NOT NULL    UNIQUE
                                        REFERENCES salles(id) ON DELETE CASCADE,
    capacite_max                    INTEGER     NOT NULL    DEFAULT 100
                                        CHECK (capacite_max > 0),
    delai_reservation_min           INTEGER     NOT NULL    DEFAULT 30,
    qr_code_actif                   BOOLEAN     NOT NULL    DEFAULT TRUE,
    face_id_actif                   BOOLEAN     NOT NULL    DEFAULT FALSE,
    invitations_actives             BOOLEAN     NOT NULL    DEFAULT FALSE,
    pass_journalier_actif           BOOLEAN     NOT NULL    DEFAULT FALSE,
    boutique_active                 BOOLEAN     NOT NULL    DEFAULT FALSE,
    crm_actif                       BOOLEAN     NOT NULL    DEFAULT FALSE,
    notifications_email_actif       BOOLEAN     NOT NULL    DEFAULT TRUE,
    notifications_sms_actif         BOOLEAN     NOT NULL    DEFAULT FALSE,
    notifications_push_actif        BOOLEAN     NOT NULL    DEFAULT FALSE,
    alerte_expiration_j_moins_7     BOOLEAN     NOT NULL    DEFAULT TRUE,
    alerte_expiration_j_moins_3     BOOLEAN     NOT NULL    DEFAULT TRUE,
    alerte_expiration_j_moins_1     BOOLEAN     NOT NULL    DEFAULT TRUE,
    renouvellement_auto_actif       BOOLEAN     NOT NULL    DEFAULT FALSE,
    code_couleur_principal          VARCHAR(7)  NOT NULL    DEFAULT '#FF6B00',
    code_couleur_secondaire         VARCHAR(7)  NOT NULL    DEFAULT '#0D0D0D',
    message_accueil_borne           VARCHAR(300) DEFAULT 'Bienvenue !',
    son_acces_autorise_url          VARCHAR(500),
    son_acces_refuse_url            VARCHAR(500),
    cree_le                         TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le                      TIMESTAMPTZ NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE parametres_salles
    IS 'Paramètres fonctionnels et d''affichage de chaque salle (1 ligne par salle)';

-- -----------------------------------------------------------------------------
-- 4.11  membres
--       Adhérents inscrits dans une salle
-- -----------------------------------------------------------------------------
CREATE TABLE membres (
    id                      SERIAL          PRIMARY KEY,
    salle_id                INTEGER         NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    nom                     VARCHAR(100)    NOT NULL,
    prenom                  VARCHAR(100)    NOT NULL,
    email                   VARCHAR(255)    NOT NULL,
    mot_de_passe_hash       VARCHAR(255),
    telephone               VARCHAR(30),
    date_naissance          DATE,
    sexe                    sexe_membre     NOT NULL    DEFAULT 'NON_SPECIFIE',
    adresse                 VARCHAR(300),
    ville                   VARCHAR(100),
    code_membre             VARCHAR(50)     NOT NULL,
    photo_url               VARCHAR(500),
    est_actif               BOOLEAN         NOT NULL    DEFAULT TRUE,
    est_verifie             BOOLEAN         NOT NULL    DEFAULT FALSE,
    token_verification      VARCHAR(128)    UNIQUE,
    token_reinit_mdp        VARCHAR(128)    UNIQUE,
    expiration_token_reinit TIMESTAMPTZ,
    nb_tentatives_echouees  SMALLINT        NOT NULL    DEFAULT 0,
    verrouille_jusqu_a      TIMESTAMPTZ,
    notes                   TEXT,
    derniere_connexion      TIMESTAMPTZ,
    date_inscription        TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_membres_email CHECK (
        email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT ck_membres_date_naissance CHECK (
        date_naissance IS NULL OR date_naissance < CURRENT_DATE
    ),
    UNIQUE (salle_id, email),
    UNIQUE (salle_id, code_membre)
);

COMMENT ON TABLE membres IS 'Adhérents inscrits dans une salle';
COMMENT ON COLUMN membres.code_membre
    IS 'Code unique par salle — généré automatiquement (ex: MB-0001)';

-- -----------------------------------------------------------------------------
-- 4.12  consentements_rgpd
--       Traçabilité des consentements RGPD des membres
-- -----------------------------------------------------------------------------
CREATE TABLE consentements_rgpd (
    id                  SERIAL              PRIMARY KEY,
    membre_id           INTEGER             NOT NULL
                            REFERENCES membres(id) ON DELETE CASCADE,
    type_consentement   type_consentement   NOT NULL,
    est_accorde         BOOLEAN             NOT NULL    DEFAULT FALSE,
    date_consentement   TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    ip_adresse          INET,
    user_agent          VARCHAR(500),
    version_document    VARCHAR(20)         NOT NULL    DEFAULT '1.0',
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    UNIQUE (membre_id, type_consentement)
);

COMMENT ON TABLE consentements_rgpd
    IS 'Historique des consentements RGPD par membre (Face ID, Marketing, etc.)';

-- -----------------------------------------------------------------------------
-- 4.13  plans_abonnement
--       Plans d'abonnement définis par chaque salle
-- -----------------------------------------------------------------------------
CREATE TABLE plans_abonnement (
    id                          SERIAL          PRIMARY KEY,
    salle_id                    INTEGER         NOT NULL
                                    REFERENCES salles(id) ON DELETE RESTRICT,
    nom                         VARCHAR(200)    NOT NULL,
    description                 TEXT,
    duree_jours                 INTEGER         NOT NULL    CHECK (duree_jours > 0),
    prix                        NUMERIC(10, 2)  NOT NULL    CHECK (prix >= 0),
    est_premium                 BOOLEAN         NOT NULL    DEFAULT FALSE,
    max_invitations_par_mois    INTEGER         NOT NULL    DEFAULT 0
                                    CHECK (max_invitations_par_mois >= 0),
    acces_boutique              BOOLEAN         NOT NULL    DEFAULT FALSE,
    acces_face_id               BOOLEAN         NOT NULL    DEFAULT FALSE,
    nb_seances_max              INTEGER,                    -- NULL = illimité
    avantages                   JSONB           NOT NULL    DEFAULT '[]'::JSONB,
    est_actif                   BOOLEAN         NOT NULL    DEFAULT TRUE,
    ordre_affichage             SMALLINT        NOT NULL    DEFAULT 0,
    cree_le                     TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le                  TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE plans_abonnement
    IS 'Plans d''abonnement définis par chaque salle (mensuel, trimestriel, annuel...)';
COMMENT ON COLUMN plans_abonnement.est_premium
    IS 'TRUE = plan premium — donne droit au système d''invitations';

-- -----------------------------------------------------------------------------
-- 4.14  abonnements_membres
--       Souscriptions des membres à un plan
-- -----------------------------------------------------------------------------
CREATE TABLE abonnements_membres (
    id                      SERIAL              PRIMARY KEY,
    salle_id                INTEGER             NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id               INTEGER             NOT NULL
                                REFERENCES membres(id) ON DELETE RESTRICT,
    plan_id                 INTEGER             NOT NULL
                                REFERENCES plans_abonnement(id) ON DELETE RESTRICT,
    paiement_id             INTEGER,                        -- FK ajoutée plus bas
    date_debut              DATE                NOT NULL,
    date_fin                DATE                NOT NULL,
    date_fin_reelle         DATE,                           -- Après gel(s)
    statut                  statut_abonnement   NOT NULL    DEFAULT 'EN_ATTENTE',
    jours_restants_gel      INTEGER             NOT NULL    DEFAULT 0
                                CHECK (jours_restants_gel >= 0),
    date_suspension         TIMESTAMPTZ,
    motif_suspension        TEXT,
    motif_annulation        TEXT,
    est_renouvellement_auto BOOLEAN             NOT NULL    DEFAULT FALSE,
    nb_seances_utilisees    INTEGER             NOT NULL    DEFAULT 0,
    prix_paye               NUMERIC(10, 2)      NOT NULL    CHECK (prix_paye >= 0),
    notes                   TEXT,
    cree_par_employe_id     INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    cree_le                 TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_abonnements_dates CHECK (date_fin > date_debut)
);

COMMENT ON TABLE abonnements_membres IS 'Souscriptions des membres à un plan d''abonnement';

-- -----------------------------------------------------------------------------
-- 4.15  codes_qr_membres
--       QR Codes générés pour les membres (permanent + temporaires)
-- -----------------------------------------------------------------------------
CREATE TABLE codes_qr_membres (
    id                  SERIAL          PRIMARY KEY,
    salle_id            INTEGER         NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id           INTEGER                             -- NULL pour QR temporaire sans compte
                            REFERENCES membres(id) ON DELETE CASCADE,
    code_qr             VARCHAR(500)    NOT NULL    UNIQUE,
    signature_hmac      VARCHAR(300)    NOT NULL,
    est_actif           BOOLEAN         NOT NULL    DEFAULT TRUE,
    est_temporaire      BOOLEAN         NOT NULL    DEFAULT FALSE,
    date_expiration     TIMESTAMPTZ,                        -- NULL = permanent
    max_utilisations    SMALLINT,                           -- NULL = illimité (QR permanent)
    nb_utilisations     INTEGER         NOT NULL    DEFAULT 0,
    description         VARCHAR(200),
    cree_par_gestionnaire_id INTEGER
                            REFERENCES gestionnaires(id) ON DELETE SET NULL,
    cree_par_employe_id INTEGER
                            REFERENCES employes(id) ON DELETE SET NULL,
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_qr_membre_ou_temporaire
        CHECK (membre_id IS NOT NULL OR est_temporaire = TRUE),
    CONSTRAINT ck_qr_utilisations
        CHECK (max_utilisations IS NULL OR nb_utilisations <= max_utilisations)
);

COMMENT ON TABLE codes_qr_membres
    IS 'QR Codes membres (HMAC-SHA256) — permanents et temporaires (usage unique, 7j)';

-- -----------------------------------------------------------------------------
-- 4.16  journaux_acces
--       Historique de toutes les tentatives d'accès à la borne
-- -----------------------------------------------------------------------------
CREATE TABLE journaux_acces (
    id                  BIGSERIAL       PRIMARY KEY,
    salle_id            INTEGER         NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id           INTEGER
                            REFERENCES membres(id) ON DELETE SET NULL,
    abonnement_id       INTEGER
                            REFERENCES abonnements_membres(id) ON DELETE SET NULL,
    qr_code_id          INTEGER
                            REFERENCES codes_qr_membres(id) ON DELETE SET NULL,
    invitation_id       INTEGER,                            -- FK ajoutée plus bas
    methode             methode_acces   NOT NULL,
    statut              statut_acces    NOT NULL,
    motif_refus_detail  TEXT,
    confiance_face_id   NUMERIC(5, 2)
                            CHECK (confiance_face_id IS NULL
                                   OR confiance_face_id BETWEEN 0 AND 100),
    ip_borne            INET,
    identifiant_borne   VARCHAR(100),
    donnees_extra       JSONB           NOT NULL    DEFAULT '{}'::JSONB,
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE journaux_acces
    IS 'Toutes les tentatives d''accès (autorisées ou refusées) à la borne';
COMMENT ON COLUMN journaux_acces.cree_le
    IS 'Immuable — jamais de modifie_le sur cette table (log d''audit)';

-- Partitionnement recommandé en production par mois :
-- CREATE TABLE journaux_acces_2026_05 PARTITION OF journaux_acces
--     FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- -----------------------------------------------------------------------------
-- 4.17  face_id_membres
--       Templates faciaux chiffrés (RGPD-ready)
-- -----------------------------------------------------------------------------
CREATE TABLE face_id_membres (
    id                      SERIAL      PRIMARY KEY,
    membre_id               INTEGER     NOT NULL    UNIQUE
                                REFERENCES membres(id) ON DELETE CASCADE,
    salle_id                INTEGER     NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    vecteur_chiffre         BYTEA       NOT NULL,           -- AES-256 sur 128-float vector
    algorithme_version      VARCHAR(30) NOT NULL    DEFAULT 'deepface-v1',
    est_actif               BOOLEAN     NOT NULL    DEFAULT TRUE,
    seuil_confiance_perso   NUMERIC(5, 2)           -- NULL = seuil global (95%)
                                CHECK (seuil_confiance_perso IS NULL
                                       OR seuil_confiance_perso BETWEEN 50 AND 100),
    nb_reconnaissances_ok   INTEGER     NOT NULL    DEFAULT 0,
    nb_reconnaissances_ko   INTEGER     NOT NULL    DEFAULT 0,
    date_enrollment         TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    date_derniere_utilisation TIMESTAMPTZ,
    cree_le                 TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE face_id_membres
    IS 'Templates faciaux — vecteur chiffré AES-256 (jamais image brute stockée)';
COMMENT ON COLUMN face_id_membres.vecteur_chiffre
    IS 'Vecteur 128-float encodé en bytes et chiffré AES-256-CBC — clé dans variables d''env';

-- -----------------------------------------------------------------------------
-- 4.18  invitations_premium
--       Invitations envoyées par des membres premium
-- -----------------------------------------------------------------------------
CREATE TABLE invitations_premium (
    id                      SERIAL              PRIMARY KEY,
    salle_id                INTEGER             NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    membre_inviteur_id      INTEGER             NOT NULL
                                REFERENCES membres(id) ON DELETE RESTRICT,
    email_invite            VARCHAR(255)        NOT NULL,
    nom_invite              VARCHAR(200),
    prenom_invite           VARCHAR(200),
    code_invitation         VARCHAR(64)         NOT NULL    UNIQUE,
    message_personnel       TEXT,
    statut                  statut_invitation   NOT NULL    DEFAULT 'EN_ATTENTE',
    date_invitation         TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    date_expiration         TIMESTAMPTZ         NOT NULL    DEFAULT NOW() + INTERVAL '7 days',
    date_acceptation        TIMESTAMPTZ,
    date_utilisation        TIMESTAMPTZ,
    journal_acces_id        BIGINT
                                REFERENCES journaux_acces(id) ON DELETE SET NULL,
    membre_converti_id      INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    cree_le                 TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_invitations_email CHECK (
        email_invite ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

COMMENT ON TABLE invitations_premium
    IS 'Invitations d''accès journalier envoyées par membres premium (1/jour max)';

-- -----------------------------------------------------------------------------
-- 4.19  credits_journaliers
--       Solde de crédits PASS journalier (membres et visiteurs)
-- -----------------------------------------------------------------------------
CREATE TABLE credits_journaliers (
    id                  SERIAL      PRIMARY KEY,
    salle_id            INTEGER     NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id           INTEGER
                            REFERENCES membres(id) ON DELETE CASCADE,
    solde_credits       INTEGER     NOT NULL    DEFAULT 0
                            CHECK (solde_credits >= 0),
    total_achete        INTEGER     NOT NULL    DEFAULT 0,
    total_utilise       INTEGER     NOT NULL    DEFAULT 0,
    derniere_recharge   TIMESTAMPTZ,
    alerte_solde_faible BOOLEAN     NOT NULL    DEFAULT TRUE,
    seuil_alerte        INTEGER     NOT NULL    DEFAULT 2,
    cree_le             TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ NOT NULL    DEFAULT NOW(),

    UNIQUE (salle_id, membre_id)
);

COMMENT ON TABLE credits_journaliers
    IS 'Portefeuille de crédits PASS journalier par membre/visiteur par salle';

-- -----------------------------------------------------------------------------
-- 4.20  pass_en_ligne
--       PASS journaliers achetés en ligne par des visiteurs
-- -----------------------------------------------------------------------------
CREATE TABLE pass_en_ligne (
    id                  SERIAL      PRIMARY KEY,
    salle_id            INTEGER     NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    credits_id          INTEGER
                            REFERENCES credits_journaliers(id) ON DELETE SET NULL,
    nom                 VARCHAR(100) NOT NULL,
    prenom              VARCHAR(100) NOT NULL,
    email               VARCHAR(255) NOT NULL,
    telephone           VARCHAR(30),
    date_achat          TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    date_validite       DATE        NOT NULL    DEFAULT CURRENT_DATE,
    est_utilise         BOOLEAN     NOT NULL    DEFAULT FALSE,
    date_utilisation    TIMESTAMPTZ,
    journal_acces_id    BIGINT
                            REFERENCES journaux_acces(id) ON DELETE SET NULL,
    cree_le             TIMESTAMPTZ NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_pass_email CHECK (
        email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

COMMENT ON TABLE pass_en_ligne
    IS 'PASS journaliers en ligne pour visiteurs occasionnels';

-- -----------------------------------------------------------------------------
-- 4.21  paiements
--       Tous les paiements enregistrés dans le système
-- -----------------------------------------------------------------------------
CREATE TABLE paiements (
    id                      SERIAL          PRIMARY KEY,
    salle_id                INTEGER         NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id               INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    employe_caissier_id     INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    objet                   objet_paiement  NOT NULL,
    montant                 NUMERIC(12, 2)  NOT NULL    CHECK (montant > 0),
    moyen                   moyen_paiement  NOT NULL,
    statut                  statut_paiement NOT NULL    DEFAULT 'EN_ATTENTE',
    reference_externe       VARCHAR(300),               -- Stripe/PayDunya transaction ID
    reference_interne       VARCHAR(50)     NOT NULL    UNIQUE,
    montant_rembourse       NUMERIC(12, 2)  NOT NULL    DEFAULT 0.00
                                CHECK (montant_rembourse >= 0),
    date_remboursement      TIMESTAMPTZ,
    motif_remboursement     TEXT,
    admin_remboursement_id  INTEGER
                                REFERENCES admins_plateforme(id) ON DELETE SET NULL,
    devise                  VARCHAR(10)     NOT NULL    DEFAULT 'XOF',
    taux_change             NUMERIC(10, 4)  NOT NULL    DEFAULT 1.0000,
    notes                   TEXT,
    donnees_passerelle      JSONB           NOT NULL    DEFAULT '{}'::JSONB,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_paiements_remboursement
        CHECK (montant_rembourse <= montant)
);

COMMENT ON TABLE paiements
    IS 'Transactions financières : abonnements, PASS, produits, licences';
COMMENT ON COLUMN paiements.reference_interne
    IS 'Référence interne (ex: PAY-2026-00001) générée automatiquement';
COMMENT ON COLUMN paiements.donnees_passerelle
    IS 'Réponse brute de la passerelle de paiement (Stripe/PayDunya) — JSON';

-- FK circulaire paiements ↔ abonnements_membres
ALTER TABLE abonnements_membres
    ADD CONSTRAINT fk_abonnements_paiement
        FOREIGN KEY (paiement_id) REFERENCES paiements(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 4.22  categories_produits
--       Catégories de la boutique interne de chaque salle
-- -----------------------------------------------------------------------------
CREATE TABLE categories_produits (
    id                  SERIAL          PRIMARY KEY,
    salle_id            INTEGER         NOT NULL
                            REFERENCES salles(id) ON DELETE CASCADE,
    nom                 VARCHAR(150)    NOT NULL,
    description         TEXT,
    icone_url           VARCHAR(500),
    ordre_affichage     SMALLINT        NOT NULL    DEFAULT 0,
    est_actif           BOOLEAN         NOT NULL    DEFAULT TRUE,
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    UNIQUE (salle_id, nom)
);

-- -----------------------------------------------------------------------------
-- 4.23  produits
--       Catalogue produits de la boutique d'une salle
-- -----------------------------------------------------------------------------
CREATE TABLE produits (
    id                  SERIAL          PRIMARY KEY,
    salle_id            INTEGER         NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    categorie_id        INTEGER         NOT NULL
                            REFERENCES categories_produits(id) ON DELETE RESTRICT,
    nom                 VARCHAR(200)    NOT NULL,
    description         TEXT,
    sku                 VARCHAR(100)    NOT NULL,
    prix_vente          NUMERIC(10, 2)  NOT NULL    CHECK (prix_vente >= 0),
    prix_achat          NUMERIC(10, 2)              CHECK (prix_achat IS NULL OR prix_achat >= 0),
    stock_actuel        INTEGER         NOT NULL    DEFAULT 0   CHECK (stock_actuel >= 0),
    stock_minimum       INTEGER         NOT NULL    DEFAULT 5   CHECK (stock_minimum >= 0),
    stock_illimite      BOOLEAN         NOT NULL    DEFAULT FALSE,
    photo_url           VARCHAR(500),
    tva_pct             NUMERIC(5, 2)   NOT NULL    DEFAULT 0.00
                            CHECK (tva_pct BETWEEN 0 AND 100),
    est_actif           BOOLEAN         NOT NULL    DEFAULT TRUE,
    est_en_vitrine      BOOLEAN         NOT NULL    DEFAULT FALSE,
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    UNIQUE (salle_id, sku)
);

COMMENT ON COLUMN produits.stock_illimite
    IS 'TRUE = service immatériel ou stock non géré (cours, coaching...)';

-- -----------------------------------------------------------------------------
-- 4.24  commandes
--       Commandes passées par des membres ou en caisse
-- -----------------------------------------------------------------------------
CREATE TABLE commandes (
    id                  SERIAL              PRIMARY KEY,
    salle_id            INTEGER             NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    membre_id           INTEGER
                            REFERENCES membres(id) ON DELETE SET NULL,
    employe_caissier_id INTEGER
                            REFERENCES employes(id) ON DELETE SET NULL,
    paiement_id         INTEGER
                            REFERENCES paiements(id) ON DELETE SET NULL,
    statut              statut_commande     NOT NULL    DEFAULT 'EN_COURS',
    sous_total_ht       NUMERIC(12, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (sous_total_ht >= 0),
    total_tva           NUMERIC(12, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (total_tva >= 0),
    total_ttc           NUMERIC(12, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (total_ttc >= 0),
    remise_appliquee    NUMERIC(12, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (remise_appliquee >= 0),
    total_final         NUMERIC(12, 2)      NOT NULL    DEFAULT 0.00
                            CHECK (total_final >= 0),
    note                TEXT,
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ         NOT NULL    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4.25  lignes_commande
--       Lignes détail d'une commande
-- -----------------------------------------------------------------------------
CREATE TABLE lignes_commande (
    id                  SERIAL          PRIMARY KEY,
    commande_id         INTEGER         NOT NULL
                            REFERENCES commandes(id) ON DELETE CASCADE,
    produit_id          INTEGER         NOT NULL
                            REFERENCES produits(id) ON DELETE RESTRICT,
    quantite            INTEGER         NOT NULL    CHECK (quantite > 0),
    prix_unitaire_ht    NUMERIC(10, 2)  NOT NULL    CHECK (prix_unitaire_ht >= 0),
    tva_pct             NUMERIC(5, 2)   NOT NULL    DEFAULT 0.00,
    sous_total_ht       NUMERIC(12, 2)  GENERATED ALWAYS AS
                            (ROUND(quantite * prix_unitaire_ht, 2)) STORED,
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4.26  promotions
--       Offres promotionnelles créées par les gestionnaires
-- -----------------------------------------------------------------------------
CREATE TABLE promotions (
    id                  SERIAL              PRIMARY KEY,
    salle_id            INTEGER             NOT NULL
                            REFERENCES salles(id) ON DELETE RESTRICT,
    nom                 VARCHAR(200)        NOT NULL,
    description         TEXT,
    type                type_promotion      NOT NULL,
    valeur              NUMERIC(10, 2)      NOT NULL    CHECK (valeur > 0),
    code_promo          VARCHAR(50)         UNIQUE,     -- NULL = automatique (pas de code)
    max_utilisations    INTEGER,                        -- NULL = illimité
    nb_utilisations     INTEGER             NOT NULL    DEFAULT 0,
    max_par_membre      SMALLINT            NOT NULL    DEFAULT 1,
    date_debut          TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    date_fin            TIMESTAMPTZ,
    applicable_abonnement BOOLEAN           NOT NULL    DEFAULT TRUE,
    applicable_boutique   BOOLEAN           NOT NULL    DEFAULT FALSE,
    applicable_pass       BOOLEAN           NOT NULL    DEFAULT FALSE,
    est_actif           BOOLEAN             NOT NULL    DEFAULT TRUE,
    cree_le             TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_promotions_dates
        CHECK (date_fin IS NULL OR date_fin > date_debut),
    CONSTRAINT ck_promotions_utilisations
        CHECK (max_utilisations IS NULL OR nb_utilisations <= max_utilisations)
);

-- -----------------------------------------------------------------------------
-- 4.27  utilisations_promotions
--       Traçabilité des usages de codes promo
-- -----------------------------------------------------------------------------
CREATE TABLE utilisations_promotions (
    id                      SERIAL          PRIMARY KEY,
    promotion_id            INTEGER         NOT NULL
                                REFERENCES promotions(id) ON DELETE RESTRICT,
    membre_id               INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    paiement_id             INTEGER
                                REFERENCES paiements(id) ON DELETE SET NULL,
    abonnement_id           INTEGER
                                REFERENCES abonnements_membres(id) ON DELETE SET NULL,
    commande_id             INTEGER
                                REFERENCES commandes(id) ON DELETE SET NULL,
    valeur_remise_appliquee NUMERIC(12, 2)  NOT NULL    CHECK (valeur_remise_appliquee > 0),
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4.28  abonnements_push
--       Souscriptions Web Push Notification des membres
-- -----------------------------------------------------------------------------
CREATE TABLE abonnements_push (
    id                  SERIAL          PRIMARY KEY,
    membre_id           INTEGER         NOT NULL
                            REFERENCES membres(id) ON DELETE CASCADE,
    salle_id            INTEGER         NOT NULL
                            REFERENCES salles(id) ON DELETE CASCADE,
    endpoint_url        TEXT            NOT NULL,
    auth_key            VARCHAR(300)    NOT NULL,
    p256dh_key          VARCHAR(300)    NOT NULL,
    est_actif           BOOLEAN         NOT NULL    DEFAULT TRUE,
    user_agent          VARCHAR(500),
    cree_le             TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le          TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    UNIQUE (membre_id, salle_id, endpoint_url)
);

-- -----------------------------------------------------------------------------
-- 4.29  notifications
--       Notifications envoyées aux membres ou employés
-- -----------------------------------------------------------------------------
CREATE TABLE notifications (
    id                          SERIAL              PRIMARY KEY,
    salle_id                    INTEGER             NOT NULL
                                    REFERENCES salles(id) ON DELETE RESTRICT,
    destinataire_membre_id      INTEGER
                                    REFERENCES membres(id) ON DELETE CASCADE,
    destinataire_employe_id     INTEGER
                                    REFERENCES employes(id) ON DELETE CASCADE,
    titre                       VARCHAR(200)        NOT NULL,
    message                     TEXT                NOT NULL,
    canal                       canal_notification  NOT NULL,
    est_lue                     BOOLEAN             NOT NULL    DEFAULT FALSE,
    date_lecture                TIMESTAMPTZ,
    url_action                  VARCHAR(500),
    est_envoyee                 BOOLEAN             NOT NULL    DEFAULT FALSE,
    date_envoi                  TIMESTAMPTZ,
    erreur_envoi                TEXT,
    donnees_extra               JSONB               NOT NULL    DEFAULT '{}'::JSONB,
    cree_le                     TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_notif_destinataire
        CHECK (destinataire_membre_id IS NOT NULL
               OR destinataire_employe_id IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 4.30  campagnes_marketing
--       Campagnes d'emailing / SMS / push des gestionnaires
-- -----------------------------------------------------------------------------
CREATE TABLE campagnes_marketing (
    id                      SERIAL              PRIMARY KEY,
    salle_id                INTEGER             NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    gestionnaire_cree_par   INTEGER
                                REFERENCES gestionnaires(id) ON DELETE SET NULL,
    nom                     VARCHAR(200)        NOT NULL,
    description             TEXT,
    type                    type_campagne       NOT NULL,
    segment_cible           JSONB               NOT NULL    DEFAULT '{}'::JSONB,
    sujet_email             VARCHAR(300),
    contenu_email           TEXT,
    contenu_sms             VARCHAR(160),
    contenu_push            TEXT,
    url_action_push         VARCHAR(500),
    date_envoi_programmee   TIMESTAMPTZ,
    date_envoi_reel         TIMESTAMPTZ,
    nb_destinataires        INTEGER             NOT NULL    DEFAULT 0,
    nb_envoyes              INTEGER             NOT NULL    DEFAULT 0,
    nb_ouvertures           INTEGER             NOT NULL    DEFAULT 0,
    nb_clics                INTEGER             NOT NULL    DEFAULT 0,
    nb_erreurs              INTEGER             NOT NULL    DEFAULT 0,
    est_envoyee             BOOLEAN             NOT NULL    DEFAULT FALSE,
    est_automatique         BOOLEAN             NOT NULL    DEFAULT FALSE,
    cree_le                 TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ         NOT NULL    DEFAULT NOW()
);

COMMENT ON COLUMN campagnes_marketing.segment_cible
    IS 'Critères JSON de ciblage (ex: {"statut": "EXPIRE", "plan_id": 3})';

-- -----------------------------------------------------------------------------
-- 4.31  leads_crm
--       Prospects commerciaux des salles (visiteurs PASS, invités...)
-- -----------------------------------------------------------------------------
CREATE TABLE leads_crm (
    id                      SERIAL          PRIMARY KEY,
    salle_id                INTEGER         NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    nom                     VARCHAR(100)    NOT NULL,
    prenom                  VARCHAR(100),
    email                   VARCHAR(255),
    telephone               VARCHAR(30),
    statut                  statut_lead     NOT NULL    DEFAULT 'FROID',
    source                  source_lead     NOT NULL    DEFAULT 'FORMULAIRE_WEB',
    notes                   TEXT,
    score                   SMALLINT        NOT NULL    DEFAULT 0
                                CHECK (score BETWEEN 0 AND 100),
    date_premier_contact    TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    date_derniere_activite  TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    date_conversion         TIMESTAMPTZ,
    membre_converti_id      INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    invite_par_membre_id    INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    attribution_employe_id  INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4.32  tickets_support
--       Tickets d'assistance ouverts par membres ou employés
-- -----------------------------------------------------------------------------
CREATE TABLE tickets_support (
    id                      SERIAL              PRIMARY KEY,
    salle_id                INTEGER             NOT NULL
                                REFERENCES salles(id) ON DELETE RESTRICT,
    membre_auteur_id        INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    employe_auteur_id       INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    gestionnaire_auteur_id  INTEGER
                                REFERENCES gestionnaires(id) ON DELETE SET NULL,
    titre                   VARCHAR(300)        NOT NULL,
    description             TEXT                NOT NULL,
    statut                  statut_ticket       NOT NULL    DEFAULT 'OUVERT',
    priorite                priorite_ticket     NOT NULL    DEFAULT 'NORMALE',
    categorie               VARCHAR(100),
    admin_assigne_id        INTEGER
                                REFERENCES admins_plateforme(id) ON DELETE SET NULL,
    employe_assigne_id      INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    est_escalade_sa         BOOLEAN             NOT NULL    DEFAULT FALSE,
    date_escalade           TIMESTAMPTZ,
    ferme_le                TIMESTAMPTZ,
    cree_le                 TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ         NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_ticket_auteur
        CHECK (membre_auteur_id IS NOT NULL
               OR employe_auteur_id IS NOT NULL
               OR gestionnaire_auteur_id IS NOT NULL)
);

-- -----------------------------------------------------------------------------
-- 4.33  messages_tickets
--       Messages échangés dans un ticket support
-- -----------------------------------------------------------------------------
CREATE TABLE messages_tickets (
    id                      SERIAL      PRIMARY KEY,
    ticket_id               INTEGER     NOT NULL
                                REFERENCES tickets_support(id) ON DELETE CASCADE,
    auteur_admin_id         INTEGER
                                REFERENCES admins_plateforme(id) ON DELETE SET NULL,
    auteur_employe_id       INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    auteur_gestionnaire_id  INTEGER
                                REFERENCES gestionnaires(id) ON DELETE SET NULL,
    auteur_membre_id        INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    contenu                 TEXT        NOT NULL,
    est_interne             BOOLEAN     NOT NULL    DEFAULT FALSE,
    pieces_jointes          JSONB       NOT NULL    DEFAULT '[]'::JSONB,
    cree_le                 TIMESTAMPTZ NOT NULL    DEFAULT NOW(),

    CONSTRAINT ck_message_auteur
        CHECK (auteur_admin_id IS NOT NULL
               OR auteur_employe_id IS NOT NULL
               OR auteur_gestionnaire_id IS NOT NULL
               OR auteur_membre_id IS NOT NULL)
);

COMMENT ON COLUMN messages_tickets.est_interne
    IS 'TRUE = message interne (visible uniquement par le staff, pas par le membre)';

-- -----------------------------------------------------------------------------
-- 4.34  journaux_actions
--       Journal d'audit de toutes les actions importantes
-- -----------------------------------------------------------------------------
CREATE TABLE journaux_actions (
    id                      BIGSERIAL               PRIMARY KEY,
    salle_id                INTEGER
                                REFERENCES salles(id) ON DELETE SET NULL,
    acteur_admin_id         INTEGER
                                REFERENCES admins_plateforme(id) ON DELETE SET NULL,
    acteur_gestionnaire_id  INTEGER
                                REFERENCES gestionnaires(id) ON DELETE SET NULL,
    acteur_employe_id       INTEGER
                                REFERENCES employes(id) ON DELETE SET NULL,
    acteur_membre_id        INTEGER
                                REFERENCES membres(id) ON DELETE SET NULL,
    type_action             type_action_audit       NOT NULL,
    entite_type             VARCHAR(100)            NOT NULL,
    entite_id               INTEGER,
    description             TEXT                    NOT NULL,
    donnees_avant           JSONB,
    donnees_apres           JSONB,
    ip_adresse              INET,
    user_agent              VARCHAR(500),
    cree_le                 TIMESTAMPTZ             NOT NULL    DEFAULT NOW()
);

COMMENT ON TABLE journaux_actions
    IS 'Audit log immuable — NE PAS ajouter de colonne modifie_le sur cette table';

-- -----------------------------------------------------------------------------
-- 4.35  journaux_systeme
--       Logs d'infrastructure — accès Super Admin uniquement
-- -----------------------------------------------------------------------------
CREATE TABLE journaux_systeme (
    id              BIGSERIAL       PRIMARY KEY,
    niveau          niveau_log      NOT NULL    DEFAULT 'INFO',
    composant       VARCHAR(100)    NOT NULL,
    message         TEXT            NOT NULL,
    stack_trace     TEXT,
    donnees_extra   JSONB           NOT NULL    DEFAULT '{}'::JSONB,
    cree_le         TIMESTAMPTZ     NOT NULL    DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 4.36  revenus_plateforme
--       Suivi mensuel des revenus AFitAccess (agrégat comptable)
-- -----------------------------------------------------------------------------
CREATE TABLE revenus_plateforme (
    id                      SERIAL          PRIMARY KEY,
    annee                   SMALLINT        NOT NULL    CHECK (annee BETWEEN 2026 AND 2100),
    mois                    SMALLINT        NOT NULL    CHECK (mois BETWEEN 1 AND 12),
    nb_salles_actives       INTEGER         NOT NULL    DEFAULT 0,
    nb_licences_pro         INTEGER         NOT NULL    DEFAULT 0,
    nb_licences_entreprise  INTEGER         NOT NULL    DEFAULT 0,
    revenus_licences        NUMERIC(14, 2)  NOT NULL    DEFAULT 0.00,
    revenus_commissions     NUMERIC(14, 2)  NOT NULL    DEFAULT 0.00,
    revenus_total           NUMERIC(14, 2)  GENERATED ALWAYS AS
                                (revenus_licences + revenus_commissions) STORED,
    cree_le                 TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),
    modifie_le              TIMESTAMPTZ     NOT NULL    DEFAULT NOW(),

    UNIQUE (annee, mois)
);

-- =============================================================================
-- 5. INDEX DE PERFORMANCE
-- =============================================================================

-- admins_plateforme
CREATE INDEX idx_admins_email            ON admins_plateforme (email);
CREATE INDEX idx_admins_role             ON admins_plateforme (role);

-- salles
CREATE INDEX idx_salles_slug             ON salles (slug);
CREATE INDEX idx_salles_statut           ON salles (statut);
CREATE INDEX idx_salles_est_actif        ON salles (est_actif);

-- licences_salles
CREATE INDEX idx_licences_salle          ON licences_salles (salle_id);
CREATE INDEX idx_licences_statut         ON licences_salles (statut);
CREATE INDEX idx_licences_date_fin       ON licences_salles (date_fin);

-- gestionnaires
CREATE INDEX idx_gest_salle              ON gestionnaires (salle_id);
CREATE INDEX idx_gest_email              ON gestionnaires (email);
CREATE INDEX idx_gest_est_actif          ON gestionnaires (est_actif);

-- employes
CREATE INDEX idx_emp_salle               ON employes (salle_id);
CREATE INDEX idx_emp_email               ON employes (email);
CREATE INDEX idx_emp_role                ON employes (role);

-- membres
CREATE INDEX idx_membres_salle           ON membres (salle_id);
CREATE INDEX idx_membres_email           ON membres (salle_id, email);
CREATE INDEX idx_membres_code            ON membres (salle_id, code_membre);
CREATE INDEX idx_membres_est_actif       ON membres (est_actif);
CREATE INDEX idx_membres_nom_prenom      ON membres USING gin (
    (to_tsvector('french', nom || ' ' || prenom))
);

-- plans_abonnement
CREATE INDEX idx_plans_salle             ON plans_abonnement (salle_id);
CREATE INDEX idx_plans_est_actif         ON plans_abonnement (est_actif);
CREATE INDEX idx_plans_premium           ON plans_abonnement (est_premium);

-- abonnements_membres
CREATE INDEX idx_abonnements_salle       ON abonnements_membres (salle_id);
CREATE INDEX idx_abonnements_membre      ON abonnements_membres (membre_id);
CREATE INDEX idx_abonnements_plan        ON abonnements_membres (plan_id);
CREATE INDEX idx_abonnements_statut      ON abonnements_membres (statut);
CREATE INDEX idx_abonnements_date_fin    ON abonnements_membres (date_fin);
CREATE INDEX idx_abonnements_actifs      ON abonnements_membres (salle_id, statut)
    WHERE statut = 'ACTIF';

-- codes_qr_membres
CREATE INDEX idx_qr_membre               ON codes_qr_membres (membre_id);
CREATE INDEX idx_qr_code                 ON codes_qr_membres (code_qr);
CREATE INDEX idx_qr_actifs               ON codes_qr_membres (est_actif)
    WHERE est_actif = TRUE;
CREATE INDEX idx_qr_temporaires          ON codes_qr_membres (est_temporaire, date_expiration)
    WHERE est_temporaire = TRUE;

-- journaux_acces (table haute volumétrie — BSOGSERIAL)
CREATE INDEX idx_acces_salle             ON journaux_acces (salle_id);
CREATE INDEX idx_acces_membre            ON journaux_acces (membre_id);
CREATE INDEX idx_acces_date              ON journaux_acces (cree_le DESC);
CREATE INDEX idx_acces_salle_date        ON journaux_acces (salle_id, cree_le DESC);
CREATE INDEX idx_acces_statut            ON journaux_acces (statut);
CREATE INDEX idx_acces_methode           ON journaux_acces (methode);

-- face_id_membres
CREATE INDEX idx_face_id_membre          ON face_id_membres (membre_id);
CREATE INDEX idx_face_id_salle           ON face_id_membres (salle_id);
CREATE INDEX idx_face_id_actif           ON face_id_membres (est_actif)
    WHERE est_actif = TRUE;

-- invitations_premium
CREATE INDEX idx_invit_salle             ON invitations_premium (salle_id);
CREATE INDEX idx_invit_inviteur          ON invitations_premium (membre_inviteur_id);
CREATE INDEX idx_invit_email             ON invitations_premium (email_invite);
CREATE INDEX idx_invit_code              ON invitations_premium (code_invitation);
CREATE INDEX idx_invit_statut            ON invitations_premium (statut);

-- paiements
CREATE INDEX idx_paie_salle              ON paiements (salle_id);
CREATE INDEX idx_paie_membre             ON paiements (membre_id);
CREATE INDEX idx_paie_statut             ON paiements (statut);
CREATE INDEX idx_paie_date               ON paiements (cree_le DESC);
CREATE INDEX idx_paie_ref_interne        ON paiements (reference_interne);
CREATE INDEX idx_paie_ref_externe        ON paiements (reference_externe)
    WHERE reference_externe IS NOT NULL;

-- produits
CREATE INDEX idx_prod_salle              ON produits (salle_id);
CREATE INDEX idx_prod_categorie          ON produits (categorie_id);
CREATE INDEX idx_prod_sku                ON produits (salle_id, sku);
CREATE INDEX idx_prod_stock_bas          ON produits (salle_id, stock_actuel)
    WHERE stock_illimite = FALSE;

-- commandes
CREATE INDEX idx_cmd_salle               ON commandes (salle_id);
CREATE INDEX idx_cmd_membre              ON commandes (membre_id);
CREATE INDEX idx_cmd_statut              ON commandes (statut);
CREATE INDEX idx_cmd_date                ON commandes (cree_le DESC);

-- promotions
CREATE INDEX idx_promo_salle             ON promotions (salle_id);
CREATE INDEX idx_promo_code              ON promotions (code_promo)
    WHERE code_promo IS NOT NULL;
CREATE INDEX idx_promo_actives           ON promotions (salle_id, date_debut, date_fin)
    WHERE est_actif = TRUE;

-- notifications
CREATE INDEX idx_notif_membre            ON notifications (destinataire_membre_id);
CREATE INDEX idx_notif_salle             ON notifications (salle_id);
CREATE INDEX idx_notif_non_lues          ON notifications (destinataire_membre_id, est_lue)
    WHERE est_lue = FALSE;

-- tickets_support
CREATE INDEX idx_tickets_salle           ON tickets_support (salle_id);
CREATE INDEX idx_tickets_statut          ON tickets_support (statut);
CREATE INDEX idx_tickets_priorite        ON tickets_support (priorite);
CREATE INDEX idx_tickets_admin           ON tickets_support (admin_assigne_id);

-- journaux_actions (audit)
CREATE INDEX idx_audit_salle             ON journaux_actions (salle_id);
CREATE INDEX idx_audit_type              ON journaux_actions (type_action);
CREATE INDEX idx_audit_entite            ON journaux_actions (entite_type, entite_id);
CREATE INDEX idx_audit_date              ON journaux_actions (cree_le DESC);

-- journaux_systeme
CREATE INDEX idx_sys_niveau              ON journaux_systeme (niveau);
CREATE INDEX idx_sys_date                ON journaux_systeme (cree_le DESC);
CREATE INDEX idx_sys_composant           ON journaux_systeme (composant);

-- =============================================================================
-- 6. TRIGGERS — Mise à jour automatique de modifie_le
-- =============================================================================

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'admins_plateforme', 'plans_licence', 'salles', 'licences_salles',
        'gestionnaires', 'employes', 'horaires_employes', 'horaires_salles',
        'parametres_salles', 'membres', 'plans_abonnement', 'abonnements_membres',
        'codes_qr_membres', 'face_id_membres', 'invitations_premium',
        'credits_journaliers', 'pass_en_ligne', 'paiements',
        'categories_produits', 'produits', 'commandes', 'promotions',
        'abonnements_push', 'campagnes_marketing', 'leads_crm',
        'tickets_support', 'revenus_plateforme'
    ]
    LOOP
        EXECUTE format(
            'CREATE TRIGGER tg_%s_modifie_le
             BEFORE UPDATE ON %s
             FOR EACH ROW EXECUTE FUNCTION fn_mise_a_jour_modifie_le()',
            t, t
        );
    END LOOP;
END;
$$;

-- =============================================================================
-- 7. VUES UTILITAIRES
-- =============================================================================

-- Vue : membres avec statut d'abonnement courant
CREATE OR REPLACE VIEW v_membres_abonnements AS
SELECT
    m.id                        AS membre_id,
    m.salle_id,
    m.nom,
    m.prenom,
    m.email,
    m.code_membre,
    m.est_actif                 AS membre_actif,
    a.id                        AS abonnement_id,
    pa.nom                      AS plan_nom,
    pa.est_premium,
    a.date_debut,
    a.date_fin,
    a.statut                    AS statut_abonnement,
    a.date_fin - CURRENT_DATE   AS jours_restants,
    CASE
        WHEN a.id IS NULL                           THEN 'SANS_ABONNEMENT'
        WHEN a.statut = 'EXPIRE'                    THEN 'EXPIRE'
        WHEN a.statut = 'SUSPENDU'                  THEN 'SUSPENDU'
        WHEN a.date_fin < CURRENT_DATE              THEN 'EXPIRE'
        WHEN a.date_fin <= CURRENT_DATE + INTERVAL '7 days' THEN 'EXPIRE_BIENTOT'
        WHEN a.statut = 'ACTIF'                     THEN 'ACTIF'
        ELSE a.statut::TEXT
    END                         AS statut_global
FROM membres m
LEFT JOIN LATERAL (
    SELECT *
    FROM abonnements_membres ab
    WHERE ab.membre_id = m.id
      AND ab.statut IN ('ACTIF', 'SUSPENDU', 'EN_ATTENTE')
    ORDER BY ab.date_fin DESC
    LIMIT 1
) a ON TRUE
LEFT JOIN plans_abonnement pa ON pa.id = a.plan_id;

COMMENT ON VIEW v_membres_abonnements
    IS 'Vue membre + statut abonnement courant calculé';

-- Vue : KPIs journaliers par salle
CREATE OR REPLACE VIEW v_kpis_salle_aujourd_hui AS
SELECT
    s.id                                AS salle_id,
    s.nom_salle,
    COUNT(DISTINCT ja.id)               AS acces_total_aujourd_hui,
    COUNT(DISTINCT ja.id)
        FILTER (WHERE ja.statut = 'AUTORISE')           AS acces_autorises,
    COUNT(DISTINCT ja.id)
        FILTER (WHERE ja.statut <> 'AUTORISE')          AS acces_refuses,
    COUNT(DISTINCT ja.membre_id)        AS membres_uniques_presentes,
    COUNT(DISTINCT m.id)
        FILTER (WHERE ab.statut = 'ACTIF'
                AND ab.date_fin >= CURRENT_DATE)        AS membres_abonnements_actifs,
    COUNT(DISTINCT m.id)
        FILTER (WHERE ab.date_fin BETWEEN CURRENT_DATE
                AND CURRENT_DATE + INTERVAL '7 days')   AS abonnements_expirent_7j,
    COALESCE(SUM(p.montant)
        FILTER (WHERE p.statut = 'COMPLETE'
                AND p.cree_le::DATE = CURRENT_DATE), 0) AS revenus_aujourd_hui
FROM salles s
LEFT JOIN journaux_acces ja
    ON ja.salle_id = s.id
    AND ja.cree_le::DATE = CURRENT_DATE
LEFT JOIN membres m ON m.salle_id = s.id AND m.est_actif = TRUE
LEFT JOIN LATERAL (
    SELECT *
    FROM abonnements_membres ab2
    WHERE ab2.membre_id = m.id
    ORDER BY ab2.date_fin DESC LIMIT 1
) ab ON TRUE
LEFT JOIN paiements p ON p.salle_id = s.id
WHERE s.est_actif = TRUE
GROUP BY s.id, s.nom_salle;

COMMENT ON VIEW v_kpis_salle_aujourd_hui
    IS 'KPIs temps réel du jour par salle (accès, membres actifs, revenus)';

-- Vue : licences proches de l'expiration (alertes Super Admin)
CREATE OR REPLACE VIEW v_licences_a_renouveler AS
SELECT
    s.id                        AS salle_id,
    s.nom_salle,
    s.email_contact,
    pl.nom                      AS plan_licence,
    l.date_fin,
    l.date_fin - CURRENT_DATE   AS jours_restants,
    l.renouvellement_auto,
    l.statut
FROM licences_salles l
JOIN salles s           ON s.id = l.salle_id
JOIN plans_licence pl   ON pl.id = l.plan_id
WHERE l.statut = 'ACTIVE'
  AND l.date_fin BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '30 days'
ORDER BY l.date_fin ASC;

-- Vue : stocks produits sous le seuil minimum
CREATE OR REPLACE VIEW v_produits_stock_bas AS
SELECT
    s.id        AS salle_id,
    s.nom_salle,
    p.id        AS produit_id,
    p.sku,
    p.nom       AS produit,
    p.stock_actuel,
    p.stock_minimum,
    p.stock_minimum - p.stock_actuel AS manque
FROM produits p
JOIN salles s ON s.id = p.salle_id
WHERE p.stock_illimite = FALSE
  AND p.est_actif = TRUE
  AND p.stock_actuel <= p.stock_minimum
ORDER BY s.id, (p.stock_minimum - p.stock_actuel) DESC;

-- Vue : récapitulatif mensuel des revenus par salle
CREATE OR REPLACE VIEW v_revenus_mensuels_salle AS
SELECT
    s.id                                                AS salle_id,
    s.nom_salle,
    DATE_TRUNC('month', p.cree_le)                      AS mois,
    COUNT(*)                                            AS nb_transactions,
    SUM(p.montant)                  FILTER (WHERE p.statut = 'COMPLETE')    AS revenus_bruts,
    SUM(p.montant_rembourse)        FILTER (WHERE p.statut IN ('REMBOURSE','PARTIELLEMENT_REMBOURSE')) AS remboursements,
    SUM(p.montant) - COALESCE(SUM(p.montant_rembourse), 0) AS revenus_nets,
    COUNT(*) FILTER (WHERE p.objet = 'ABONNEMENT')      AS ventes_abonnements,
    COUNT(*) FILTER (WHERE p.objet = 'PRODUIT')         AS ventes_produits,
    COUNT(*) FILTER (WHERE p.objet = 'PASS_JOURNALIER') AS ventes_pass
FROM paiements p
JOIN salles s ON s.id = p.salle_id
GROUP BY s.id, s.nom_salle, DATE_TRUNC('month', p.cree_le)
ORDER BY s.id, mois DESC;

-- =============================================================================
-- 8. FONCTIONS UTILITAIRES
-- =============================================================================

-- Génération d'un code membre unique par salle
CREATE OR REPLACE FUNCTION fn_generer_code_membre(p_salle_id INTEGER)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count     INTEGER;
    v_code      VARCHAR(20);
BEGIN
    SELECT COUNT(*) + 1
    INTO v_count
    FROM membres
    WHERE salle_id = p_salle_id;

    v_code := 'MB-' || LPAD(v_count::TEXT, 5, '0');

    -- Protection contre collision
    WHILE EXISTS (
        SELECT 1 FROM membres
        WHERE salle_id = p_salle_id AND code_membre = v_code
    ) LOOP
        v_count := v_count + 1;
        v_code := 'MB-' || LPAD(v_count::TEXT, 5, '0');
    END LOOP;

    RETURN v_code;
END;
$$;

-- Génération d'une référence interne de paiement
CREATE OR REPLACE FUNCTION fn_generer_reference_paiement()
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    v_annee     TEXT;
    v_seq       INTEGER;
    v_ref       VARCHAR(50);
BEGIN
    v_annee := TO_CHAR(NOW(), 'YYYY');
    SELECT COUNT(*) + 1 INTO v_seq FROM paiements
    WHERE EXTRACT(YEAR FROM cree_le) = EXTRACT(YEAR FROM NOW());
    v_ref := 'PAY-' || v_annee || '-' || LPAD(v_seq::TEXT, 6, '0');
    RETURN v_ref;
END;
$$;

-- Génération d'un numéro de facture
CREATE OR REPLACE FUNCTION fn_generer_numero_facture()
RETURNS VARCHAR(50)
LANGUAGE plpgsql
AS $$
DECLARE
    v_annee     TEXT;
    v_seq       INTEGER;
BEGIN
    v_annee := TO_CHAR(NOW(), 'YYYY');
    SELECT COUNT(*) + 1 INTO v_seq FROM factures_licences
    WHERE EXTRACT(YEAR FROM cree_le) = EXTRACT(YEAR FROM NOW());
    RETURN 'AFA-' || v_annee || '-' || LPAD(v_seq::TEXT, 5, '0');
END;
$$;

-- Vérification si un membre a un abonnement actif
CREATE OR REPLACE FUNCTION fn_membre_a_abonnement_actif(
    p_membre_id INTEGER,
    p_salle_id  INTEGER
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM abonnements_membres
        WHERE membre_id  = p_membre_id
          AND salle_id   = p_salle_id
          AND statut     = 'ACTIF'
          AND date_fin  >= CURRENT_DATE
    );
$$;

-- Mise à jour du solde crédits journaliers
CREATE OR REPLACE FUNCTION fn_debiter_credit(
    p_membre_id INTEGER,
    p_salle_id  INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_solde INTEGER;
BEGIN
    SELECT solde_credits INTO v_solde
    FROM credits_journaliers
    WHERE membre_id = p_membre_id
      AND salle_id  = p_salle_id
    FOR UPDATE;

    IF v_solde IS NULL OR v_solde < 1 THEN
        RETURN FALSE;
    END IF;

    UPDATE credits_journaliers
    SET solde_credits = solde_credits - 1,
        total_utilise  = total_utilise  + 1
    WHERE membre_id = p_membre_id
      AND salle_id  = p_salle_id;

    RETURN TRUE;
END;
$$;

-- Trigger : initialiser parametres_salles à la création d'une salle
CREATE OR REPLACE FUNCTION fn_init_parametres_salle()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO parametres_salles (salle_id)
    VALUES (NEW.id)
    ON CONFLICT (salle_id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_salles_init_parametres
    AFTER INSERT ON salles
    FOR EACH ROW EXECUTE FUNCTION fn_init_parametres_salle();

-- Trigger : incrémenter nb_utilisations du QR Code après un accès autorisé
CREATE OR REPLACE FUNCTION fn_incrementer_qr_utilisations()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.statut = 'AUTORISE' AND NEW.qr_code_id IS NOT NULL THEN
        UPDATE codes_qr_membres
        SET nb_utilisations = nb_utilisations + 1
        WHERE id = NEW.qr_code_id;

        -- Désactiver si usage unique
        UPDATE codes_qr_membres
        SET est_actif = FALSE
        WHERE id = NEW.qr_code_id
          AND est_temporaire = TRUE
          AND max_utilisations IS NOT NULL
          AND nb_utilisations >= max_utilisations;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_acces_qr_increment
    AFTER INSERT ON journaux_acces
    FOR EACH ROW EXECUTE FUNCTION fn_incrementer_qr_utilisations();

-- Trigger : incrémenter nb_utilisations d'une promotion
CREATE OR REPLACE FUNCTION fn_incrementer_promo_utilisations()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE promotions
    SET nb_utilisations = nb_utilisations + 1
    WHERE id = NEW.promotion_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_promo_increment
    AFTER INSERT ON utilisations_promotions
    FOR EACH ROW EXECUTE FUNCTION fn_incrementer_promo_utilisations();

-- Trigger : mettre à jour stock après ligne de commande confirmée
CREATE OR REPLACE FUNCTION fn_mise_a_jour_stock()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Diminuer le stock quand la commande est confirmée
    IF NEW.statut = 'CONFIRMEE' AND OLD.statut = 'EN_COURS' THEN
        UPDATE produits p
        SET stock_actuel = stock_actuel - lc.quantite
        FROM lignes_commande lc
        WHERE lc.commande_id = NEW.id
          AND lc.produit_id  = p.id
          AND p.stock_illimite = FALSE;
    END IF;
    -- Remettre le stock si annulation
    IF NEW.statut = 'ANNULEE' AND OLD.statut IN ('CONFIRMEE', 'PREPAREE') THEN
        UPDATE produits p
        SET stock_actuel = stock_actuel + lc.quantite
        FROM lignes_commande lc
        WHERE lc.commande_id = NEW.id
          AND lc.produit_id  = p.id
          AND p.stock_illimite = FALSE;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER tg_commandes_stock
    AFTER UPDATE OF statut ON commandes
    FOR EACH ROW EXECUTE FUNCTION fn_mise_a_jour_stock();

-- =============================================================================
-- 9. DONNÉES INITIALES (SEED)
-- =============================================================================

-- Plans de licence
INSERT INTO plans_licence (nom, description, prix_mensuel, prix_annuel,
    max_membres, max_employes, max_invitations_par_membre,
    face_id_inclus, boutique_incluse, crm_inclus, rapports_avances, support_prioritaire,
    fonctionnalites)
VALUES
(
    'GRATUIT',
    'Plan de démarrage — idéal pour tester AFitAccess',
    0.00, 0.00, 50, 3, 0, FALSE, FALSE, FALSE, FALSE, FALSE,
    '["QR Code accès", "Gestion membres (50 max)", "3 employés", "Dashboard basique"]'::JSONB
),
(
    'PRO',
    'Plan professionnel — pour salles en croissance',
    29900.00, 299000.00, 500, 15, 3, TRUE, TRUE, FALSE, TRUE, FALSE,
    '["QR Code accès", "Face ID", "Boutique interne", "Invitations premium (3/membre/mois)", "Rapports avancés", "PASS journalier", "500 membres", "15 employés"]'::JSONB
),
(
    'ENTREPRISE',
    'Plan entreprise — pour les grands complexes sportifs',
    79900.00, 799000.00, 9999, 100, 10, TRUE, TRUE, TRUE, TRUE, TRUE,
    '["Tout le plan PRO", "CRM & Marketing", "Support prioritaire", "Membres illimités", "100 employés", "API personnalisée", "SLA 99.9%"]'::JSONB
);

-- Super Admin initial AFitAccess
-- IMPORTANT : Changer le mot de passe après la première connexion !
-- Hash correspond à 'Admin@AFitAccess2026!' — À CHANGER EN PRODUCTION
INSERT INTO admins_plateforme (nom, prenom, email, mot_de_passe_hash, role, est_actif)
VALUES (
    'DIOP',
    'Mouhamed',
    'admin@afitaccess.com',
    crypt('Admin@AFitAccess2026!', gen_salt('bf', 12)),
    'SUPERADMIN',
    TRUE
);

-- =============================================================================
-- 10. COMMENTAIRES GÉNÉRAUX
-- =============================================================================

COMMENT ON DATABASE CURRENT_DATABASE()
    IS 'Base de données AFitAccess — SaaS de gestion de salles de sport';

-- =============================================================================
-- FIN DU SCRIPT
-- Nombre de tables  : 36
-- Nombre d'ENUMs    : 22
-- Nombre d'index    : 54
-- Nombre de vues    : 4
-- Nombre de fonctions + triggers : 10
-- Dernière mise à jour : 06 Mai 2026 — Mouhamed DIOP
-- =============================================================================
