sealed class ApprovalCheckState {
  const ApprovalCheckState();
}

class ApprovalWaiting extends ApprovalCheckState {
  const ApprovalWaiting();
}

class ApprovalChecking extends ApprovalCheckState {
  const ApprovalChecking();
}

class ApprovalStillPending extends ApprovalCheckState {
  const ApprovalStillPending();
}

class ApprovalCheckFailed extends ApprovalCheckState {
  const ApprovalCheckFailed(this.message);

  final String message;
}
