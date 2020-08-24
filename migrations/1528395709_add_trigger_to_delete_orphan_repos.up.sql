BEGIN;

DROP FUNCTION IF EXISTS soft_delete_orphan_repos();

CREATE FUNCTION soft_delete_orphan_repos() RETURNS trigger
    LANGUAGE plpgsql
AS $$
BEGIN
    -- If a user is soft-deleted, delete every row that references that user
    IF (OLD.deleted_at IS NULL AND (NEW IS NULL OR NEW.deleted_at IS NOT NULL)) THEN
        UPDATE
            repo
        SET
            name = 'DELETED-' || extract(epoch FROM transaction_timestamp()) || '-' || name,
            deleted_at = transaction_timestamp()
        WHERE
            deleted_at IS NULL
          AND id NOT IN (
            SELECT DISTINCT(repo_id) FROM external_service_repos
        );
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trig_soft_delete_orphan_repos_for_external_service
    AFTER UPDATE OF deleted_at OR DELETE ON external_services
    FOR EACH ROW EXECUTE PROCEDURE soft_delete_orphan_repos();

COMMIT;
