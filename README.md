# Kubernetes GitOps 구성 리포지토리

## 1. 프로젝트 개요

이 리포지토리는 Argo CD를 활용하여 Kubernetes 클러스터의 상태를 선언적으로 관리하기 위한 GitOps 구성 파일들을 포함한다.

모든 플랫폼 서비스(모니터링, 로깅, 스토리지), 애플리케이션 구성, CRD, 시크릿 등 클러스터를 구성하는 모든 요소는 Git을 통해 버전 관리된다. 클러스터는 Argo CD를 통해 자동으로 이 Git 리포지토리의 상태를 추적하고 동기화한다.

## 2. 핵심 원칙: App of Apps 패턴

이 리포지토리는 Argo CD의 **'App of Apps'** 패턴을 중심으로 구성된다.

`argocd-apps/gitops-app-manager.yaml` 파일이 클러스터에 배포될 모든 애플리케이션 그룹을 정의하는 루트 애플리케이션 역할을 한다. 이 루트 앱은 `argocd-apps` 하위의 `apps`, `core`, `logging`, `monitoring`, `platform` 디렉토리를 각각 바라보는 다른 Argo CD 애플리케이션들을 생성하여, 전체 시스템을 체계적으로 배포하고 관리한다.

## 3. 디렉토리 구조

```
.
├── argocd-apps/          # 클러스터에 배포될 모든 애플리케이션 그룹의 Argo CD Application 매니페스트
│   ├── apps/             # 개별 애플리케이션 (예: kubewatch)
│   ├── core/             # 핵심 인프라 구성 (예: rook-ceph values)
│   ├── logging/          # 로깅 스택 (Elasticsearch, Filebeat, Kibana)
│   ├── monitoring/       # 모니터링 스택 (Prometheus, Grafana)
│   ├── platform/         # 플랫폼 서비스 (예: rook-ceph)
│   └── gitops-app-manager.yaml # App of Apps 패턴의 진입점(Entrypoint)
│
├── k8s-app-helm-charts/  # argocd-apps에서 참조하는 커스텀 Helm 차트
│   └── kubewatch/
│
├── crds/                 # 애플리케이션들이 필요로 하는 Custom Resource Definitions (CRDs)
│   └── prometheus-operator/
│
├── secrets/              # Sealed Secrets를 이용한 암호화된 시크릿 관리
│
└── argocd-full/          # Argo CD 자체를 설치하기 위한 전체 매니페스트 (초기 설치용)
```

-   **`argocd-apps/`**: 클러스터에 배포될 모든 애플리케이션의 Argo CD `Application` CRD 매니페스트를 관리한다. `gitops-app-manager.yaml`이 이 디렉토리의 다른 애플리케이션들을 부트스트랩한다.
-   **`k8s-app-helm-charts/`**: `argocd-apps`에서 참조하는 애플리케이션들의 커스텀 Helm 차트를 보관한다.
-   **`crds/`**: Argo CD가 애플리케이션을 동기화하기 전에 클러스터에 미리 적용해야 하는 CRD(Custom Resource Definition) 파일들을 관리한다. **특히 `prometheus-operator` 관련 CRD들이 포함되어 있다.**
-   **`secrets/`**: **Bitnami Sealed Secrets**를 사용하여 암호화된 시크릿을 안전하게 관리한다. 원본 secret yaml 파일은 Git에 포함되지 않는다.
-   **`argocd-full/`**: Argo CD 자체를 클러스터에 설치하기 위한 전체 매니페스트를 포함한다. (참고용 또는 초기 설치용)

## 4. 시작 가이드

1.  **Argo CD 설치**
    클러스터에 Argo CD를 설치한다. 공식 Helm 차트를 사용하거나, 이 리포지토리의 `argocd-full/` 디렉토리 내 매니페스트를 사용할 수 있다.

2.  **Sealed Secrets 컨트롤러 설치 (중요)**
    클러스터에 Sealed Secrets 컨트롤러를 먼저 설치해야 한다. 컨트롤러가 생성하는 공개키(`pub-cert.pem`)는 시크릿을 암호화하는 데 사용된다.

3.  **CRD 선행 설치 (중요)**
    `crds/` 디렉토리의 CRD들을 클러스터에 먼저 적용해야 한다.
    ```bash
    kubectl apply -k crds/prometheus-operator/
    ```

4.  **리포지토리 등록**
    이 Git 리포지토리(`k8s-gitops-configs`)를 Argo CD에 Private Repository로 등록한다. (필요 시 인증 정보 포함)

5.  **루트 앱(Root App) 배포**
    `argocd-apps/gitops-app-manager.yaml` 파일을 `kubectl`을 사용하여 클러스터에 직접 배포한다. 이 단계를 통해 전체 GitOps 파이프라인이 시작된다.
    ```bash
    kubectl apply -f argocd-apps/gitops-app-manager.yaml
    ```

## 5. 시크릿 관리 전략: Sealed Secrets

이 리포지토리는 **Bitnami Sealed Secrets**를 사용하여 민감 정보를 안전하게 Git에서 관리한다.

**워크플로우:**
1.  `kubeseal` CLI를 설치한다.
2.  클러스터의 Sealed Secrets 컨트롤러로부터 공개키를 다운로드한다: `kubeseal --fetch-cert > pub-cert.pem`
3.  일반 Kubernetes Secret 매니페스트를 작성한다. (예: `secrets/ghcr-secret-original.yaml`)
4.  아래 명령어를 사용하여 원본 시크릿을 암호화된 `SealedSecret`으로 변환한다.
    ```bash
    kubectl create secret generic mysecret --from-literal=foo=bar --dry-run=client -o yaml | \
    kubeseal --cert pub-cert.pem > mysealedsecret.yaml
    ```
5.  생성된 `mysealedsecret.yaml` 파일만 Git에 커밋한다. 원본 시크릿 파일은 절대 커밋하지 않는다.
6.  Argo CD가 `SealedSecret`을 클러스터에 배포하면, Sealed Secrets 컨트롤러가 이를 자동으로 복호화하여 일반 `Secret` 리소스를 생성한다.
