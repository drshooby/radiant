import styles from "./SignOutButton.module.css";

interface SignOutButtonProps {
  onClick: () => void;
}

export function SignOutButton({ onClick }: SignOutButtonProps) {
  return (
    <button className={styles.button} onClick={onClick}>
      Sign Out
    </button>
  );
}
