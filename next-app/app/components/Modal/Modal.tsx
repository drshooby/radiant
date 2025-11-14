import styles from "./Modal.module.css";
import { ModalProps } from "./Modal.types";

export function Modal({
  data,
  onClose,
}: {
  data: ModalProps;
  onClose: () => void;
}) {
  return (
    <div
      className={styles.backBlur}
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby="modal-title"
    >
      <div
        className={styles.mainContainer}
        onClick={(e) => e.stopPropagation()}
        tabIndex={-1}
      >
        <div className={styles.topContainer}>
          <h1 id="modal-title" className={styles.title}>
            {data.title}
          </h1>
          <button
            className={styles.exitButton}
            onClick={onClose}
            aria-label="Close modal"
          >
            <div className={styles.exitDiagonal1}></div>
            <div className={styles.exitDiagonal2}></div>
          </button>
        </div>
        <p className={styles.message}>{data.message}</p>
      </div>
    </div>
  );
}
