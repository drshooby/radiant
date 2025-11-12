import styles from "./VideoLoading.module.css";

export function VideoLoading() {
  return (
    <div className={styles.mainContainer}>
      <div className={styles.loader}></div>
      <h2 className={styles.processingTitle}>Creating your montage</h2>
      <p className={styles.processingText}>This may take a minute...</p>
    </div>
  );
}
