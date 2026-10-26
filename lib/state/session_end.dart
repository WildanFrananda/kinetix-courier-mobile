sealed class SessionEnd {
  const SessionEnd();
}

class SessionSignedOut extends SessionEnd {
  const SessionSignedOut();
}

class SessionNotApproved extends SessionEnd {
  const SessionNotApproved();
}

class SessionUpdateRequired extends SessionEnd {
  const SessionUpdateRequired();
}
